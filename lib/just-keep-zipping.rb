require 'zip'

class JustKeepZipping
  attr_reader :entries

  def initialize
    @entries = []
    @data = ''
  end

  def current_size
    @data.size
  end

  def add(filename, body)
    io = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry filename
      zip.write body.respond_to?(:read) ? body.read : body
    end
    io.rewind
    d = Zip::CentralDirectory.read_from_stream io

    e = d.entries.first
    payload_size = 30 + e.name.length + e.compressed_size

    io.rewind
    @data += io.read(payload_size)

    e.zipfile = nil
    @entries << e
    nil
  end

  def close
    contents_size = 0
    @entries.each do |e|
      e.local_header_offset = contents_size
      contents_size += 30 + e.name.length + e.compressed_size
    end

    io = StringIO.new
    io.instance_eval "@offset = #{contents_size}"
    def io.tell
      super + @offset
    end
    Zip::CentralDirectory.new(@entries).write_to_stream io
    io.rewind
    tail = io.read
    tail.force_encoding 'ASCII-8BIT'
    @data += tail
    contents_size
  end

  def read
    data = @data
    @data = ''
    data
  end

end

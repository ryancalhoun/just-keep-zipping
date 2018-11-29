require 'zip'

# Allows the creating of large ZIP files in a streaming fashion.
#
# Example:
#   zip = JustKeepZipping.new
#   zip.add 'file1.txt', 'Data to be zipped'
#   data1 = zip.read
#   progress = Marshal.dump zip # into an object store?
#
#   zip = Marshal.load progress # load from object store?
#   zip.add 'file2.txt', 'More data to be zipped'
#   zip.close
#   data2 = zip.read
#
#   complete_archive = data1 + data2
#
class JustKeepZipping
  attr_reader :entries

  # Use the constructor for the initial object creation.
  # Use Marshal.dump and Marshal.load (e.g. with Redis) to tranfer this instance between
  # compute units (e.g. Sidekiq jobs).
  #
  def initialize
    @entries = []
    @data = ''
  end

  # The current data size. Use this as a stopping or checkpoint condition, to
  # keep memory from growing too large.
  #
  def current_size
    @data.size
  end

  # Add a file to the archive.
  #
  # Params:
  # +filename+:: a string representing the name of the file as it should appear in the archive
  # +body+:: a string or IO object that represents the contents of the file
  #
  def add(filename, body)
    io = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry filename
      zip.write body.respond_to?(:read) ? body.read : body
    end
    io.rewind
    io.set_encoding 'ASCII-8BIT'
    d = Zip::CentralDirectory.read_from_stream io

    e = d.entries.first
    payload_size = 30 + e.name.length + e.compressed_size

    io.rewind
    @data += io.read(payload_size)

    e.zipfile = nil
    @entries << e
    nil
  end

  # Finalizes the archive by adding the trailing ZIP header. A final read must be called to get the data.
  #
  # No further files should be added after calling close.
  #
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

  # Get the current ZIP data, to save in an object store like S3 or GCS.
  #
  # Do this before persisting this instance with Marshal.dump, to avoid
  # placing too much progress data into a temporary object store like Redis.
  #
  def read
    data = @data
    @data = ''
    data
  end

end

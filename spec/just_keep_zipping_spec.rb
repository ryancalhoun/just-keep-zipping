require 'rspec'
require 'tempfile'
require 'zip'

require 'just-keep-zipping'

describe JustKeepZipping do

  it 'adds a file as a string' do
    subject.add 'file', 'this is a string to be zipped'
    expect(subject.entries.size).to be == 1
    expect(subject.entries.first.name).to be == 'file'
    expect(subject.current_size).to be > subject.entries.first.compressed_size
  end

  it 'adds a file as an IO' do
    subject.add 'file', StringIO.new('this is a string to be zipped')
    expect(subject.entries.size).to be == 1
    expect(subject.entries.first.name).to be == 'file'
    expect(subject.current_size).to be > subject.entries.first.compressed_size
  end

  it 'can be marshalled' do
    subject.add 'file', 'this is a string to be zipped'

    new_instance = Marshal.load Marshal.dump subject

    expect(new_instance.entries.size).to be == 1
    expect(new_instance.entries.first.name).to be == 'file'
  end

  it 'can be read' do
    subject.add 'file', 'this is a string to be zipped'
    data = subject.read

    expect(subject.entries.size).to be == 1
    expect(subject.entries.first.name).to be == 'file'
    expect(subject.current_size).to be == 0

    expect(data.encoding.name).to be == 'ASCII-8BIT'
    expect(data.size).to be > subject.entries.first.compressed_size
  end

  it 'can be added to' do
    subject.add 'file', 'this is a string to be zipped'
    data = subject.read
    subject.add 'file2', 'this is another string to be zipped'

    expect(subject.entries.size).to be == 2
    expect(subject.entries.first.name).to be == 'file'
    expect(subject.entries.last.name).to be == 'file2'
    expect(subject.current_size).to be > subject.entries.last.compressed_size

    data2 = subject.read
    expect(data).to_not eq data2
  end

  it 'can be closed and read' do
    subject.add 'file', 'this is a string to be zipped'
    data = subject.read

    subject.close
    zip_header = subject.read

    Tempfile.open('zip') do |f|
      f.write data
      f.write zip_header
      f.rewind

      Zip::InputStream.open(f.path) do |io|
        e = io.get_next_entry
        expect(e.name).to be == 'file'
        expect(io.read).to be == 'this is a string to be zipped'
      end
    end
  end

  it 'can be closed and read and assembled' do
    subject.add 'file', 'this is a string to be zipped'
    data1 = subject.read

    new_instance = Marshal.load Marshal.dump subject
    new_instance.add 'file2', 'this is another string to be zipped'

    new_instance.close
    data2 = new_instance.read

    Tempfile.open('zip') do |f|
      f.write data1
      f.write data2
      f.rewind

      Zip::InputStream.open(f.path) do |io|
        e = io.get_next_entry
        expect(e.name).to be == 'file'
        expect(io.read).to be == 'this is a string to be zipped'

        e = io.get_next_entry
        expect(e.name).to be == 'file2'
        expect(io.read).to be == 'this is another string to be zipped'
      end
    end
  end
end

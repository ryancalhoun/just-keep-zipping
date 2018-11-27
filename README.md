# just-keep-zipping

Produce a zip file from many source files, in a streaming or distributed fashion.

## Usage

Make a complete zip of two files

	zip = JustKeepZipping.new
	zip.add 'file1.txt', 'Data to be zipped'
	zip.add 'file2.txt', 'More data to be zipped'
	zip.close

	data = zip.read

Begin a zip to be continued later

	zip = JustKeepZipping.new
	zip.add 'file1.txt', 'Data to be zipped'
	incomplete_data = zip.read
	progress_data = Marshal.dump zip

Complete an in-progress zip

	zip = Marshal.load progress_data
	zip.add 'file2.txt', 'More data to be zipped'
	zip.close

	ending_data = zip.read

Assemble the zip

	data = incomplete_data + ending_data


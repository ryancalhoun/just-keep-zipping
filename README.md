# just-keep-zipping

Produce a ZIP file from many source files, in a streaming or distributed fashion.

The ZIP format is well suited for quick updates, allowing appends of new data without needing to extract and compress
the entire archive. This is possible because the ZIP header is written at the end of the file, and a new header can be
added after new data is added. However, the file must be available locally for ZIP tools to operate effectively. If the
file is remote, then the entire archive must be downloaded, updated, then uploaded--which is a heavyweight method of
adding small files to a large archive.

Memory, disk space, and CPU time are all limits when running in a cloud environment, and it does not always scale to
require the production of an entire ZIP archive to occur within a single processing unit.

Just Keep Zipping allows a large ZIP archive to be produced in parts, on one machine or many, and can be used with
Amazon S3 or Google Cloud Storage.

The instance is Marshallable, and the `progress_data` used between steps can be stored in Redis or another object store.

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

## Amazon S3

https://docs.aws.amazon.com/sdkforruby/api/Aws/S3/Object.html#initiate_multipart_upload-instance_method

Each interval, e.g. 50-100 files, save the current data into s3. When finished, use a Multipart Upload with
`copy_part` to combine the parts into a whole.

	zip = JustKeepZipping.new
	zip.add 'file1.txt', 'Data to be zipped'

	bucket.object('part_one').put zip.read

	zip.add 'file2.txt', 'More data to be zipped'
	zip.close

	bucket.object('part_two').put zip.read

	upload = bucket.object('archive.zip').initiate_multipart_upload
	upload.part(1).copy_from copy_source: "bucket/part_one"
	upload.part(2).copy_from copy_source: "bucket/part_two"
	upload.complete compute_parts: true

## Google Cloud Storage

http://googleapis.github.io/google-cloud-ruby/docs/google-cloud-storage/latest/Google/Cloud/Storage/Bucket.html#compose-instance_method

Each interval, e.g. 50-100 files, save the current data into s3. When finished, use the compose method to join the parts
into a whole (for more than 32 parts, iteratively compose the destination file as an input of the next group).

	zip = JustKeepZipping.new
	zip.add 'file1.txt', 'Data to be zipped'

	bucket.create_file StringIO.new(zip.read), 'part_one'

	zip.add 'file2.txt', 'More data to be zipped'
	zip.close

	bucket.create_file StringIO.new(zip.read), 'part_two'

	bucket.compose ['part_one', 'part_two'], 'archive.zip'


require 'rubygems'
require 'fileutils'
require 'open3'
class Image

  def initialize(args)
    @args = args
  end

  def process
    make_images_dir
    if @args[:content_type].match(/image/)
      puts "this is an image!"
      process_as_image
    elsif @args[:content_type].match(/application\/(x-rar|x-tar|x-zip|x-7z)/)
      puts "this is an archive!"
      process_as_archive
    else
      puts @args[:content_type]
    end
  end

  def job=(job)
    @job = job
  end

  def make_images_dir
    FileUtils.mkdir @job.absolute_import_dir unless File.directory?(@job.absolute_import_dir)
    FileUtils.mkdir images_dir unless File.directory?(images_dir)
  end

  def images_dir
    File.join(@job.absolute_import_dir, 'images')
  end

  def process_as_image
    FileUtils.mv @args[:tempfile].path, File.join(images_dir, File.basename(@args[:filename]))
  end

  def process_as_archive
    @stdout = ''
    @stderr = ''
    target_file = File.join(images_dir, File.basename(@args[:filename]))
    FileUtils.mv @args[:tempfile].path, target_file
    Open3.popen3("cd #{images_dir}; #{File.join(Merb.root,'lib/decompress.sh')} #{target_file}; find #{images_dir} -type f -print0 | xargs -0 -I% mv % #{images_dir}; find #{images_dir} -type d -print0 | xargs -0 -I% rmdir %; rm #{target_file}") do |i,o,e|
      while((line = o.gets))
        @stdout << line
      end 

      while((line = e.gets))
        @stderr << line
      end 
      i.close
    end
    puts @stdout
    puts @stderr
  end

end
begin
  require 'spec/rake/spectask'

  Spec::Rake::SpecTask.new(:spec) do |t|
    t.spec_files = FileList['test/**/spec_*.rb']
    t.libs += ['lib']
    t.spec_opts = ['-rubygems','-c','-f s']
  end

  task :test => [:spec, :vgrep]
  task :default => :test
rescue
end

task :vgrep do |t|
  sh 'ruby -Ilib -rubygems test/metar.rb'
end

desc "RDoc documentation"
task :doc do
  sh 'rdoc -t "Ruby WX" -m README README TODO lib'
end

task :dist => [:doc] do
  sh 'darcs push falcon:public_html/src/ruby-wx'
  sh 'rsync -r doc falcon:public_html/src/ruby-wx'
  sh 'darcs dist -d wx-`cat VERSION`'
  sh 'scp wx-`cat VERSION`.tar.gz falcon:public_html/src/ruby-wx/'
end

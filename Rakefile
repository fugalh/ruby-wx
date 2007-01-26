begin
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['test/**/spec_*.rb']
  t.libs += ['lib']
  t.spec_opts = ['-rubygems','-c','-f s']
end

task :test => :spec
task :default => :spec
rescue
end

desc "RDoc documentation"
task :doc do
  sh 'rdoc -t "Ruby WX" -m README README TODO lib'
end

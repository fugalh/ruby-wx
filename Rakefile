require 'spec/rake/spectask'

Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['test/**/spec_*.rb']
  t.libs += ['lib']
end

task :test => :spec
task :default => :spec

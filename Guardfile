guard 'rspec', :version => 2, :all_on_start => true, :all_after_pass => true do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
end

guard 'yard' do
  watch(%r{lib/.+\.rb})
end

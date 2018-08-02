Facter.add(:local_users) do
  setcode do
    users = Array.new
    File.open("/etc/passwd").each do |line|
      next if line.match(/^\s|^#|^$/)
      users << line.split(':').first
    end
  #  users.join(',')
     users
  end
end



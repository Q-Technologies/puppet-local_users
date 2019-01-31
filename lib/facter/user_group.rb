Facter.add(:user_group) do
  confine :kernel => 'AIX'
  setcode do
    users = Array.new
    File.open("/etc/passwd").each do |line|
      next if line.match(/^\s|^#|^$/)
      users << line.split(':').first
    end
    user_group = {}
    users.each do |user|
      user_g = Facter::Util::Resolution.exec("/usr/bin/id -gn #{user}")
      if user_g
        user_group[user] = user_g
      end
    end
    user_group
  end
end


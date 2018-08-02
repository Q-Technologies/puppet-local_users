Facter.add(:user_group) do
  setcode do
    user_group = {}
    Facter.value(:local_users).each do |user|
      #user_g = Facter::Core::Exec('/usr/bin/id -gn #{user}')
      user_g = Facter::Util::Resolution.exec("/usr/bin/id -gn #{user}")
      if user_g
        user_group[user] = user_g
      end
    end
    user_group
  end
end



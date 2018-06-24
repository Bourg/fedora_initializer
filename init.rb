#!/usr/bin/ruby

require 'fileutils'

$COLS = 80
$DIVIDER = '#'

def dnf_y(cmd)
    return system("sudo dnf -y #{cmd}")
end

def rel_to_home(path)
    return File.join(ENV['HOME'], path)
end

def puts_line
    $COLS.times { print $DIVIDER }
    puts
end

def puts_divider(text)
    puts
    puts_line
    puts "#{$DIVIDER} #{text}"
    puts_line
    puts
end

def puts_output(text)
    puts ">>> #{text}"
end

def wait
    puts_output('Press enter to continue...')
    gets
end

puts_divider 'Now bootstrapped into Ruby!'

puts_divider 'Web Browser Installation'
dnf_y('install fedora-workstation-repositories')
dnf_y('config-manager --set-enabled google-chrome')
dnf_y('install google-chrome-stable')

puts_divider "SSH Configuration"

# Generate an SSH Key
puts_output "Configuring SSH key"
PUBLIC_KEYFILE = rel_to_home('.ssh/id_rsa.pub')
if File.exist?(PUBLIC_KEYFILE)
    puts_output "Key already exists!"
else
    puts_output 'No key found. Generating new key...'
    system('ssh-keygen')
    puts_output 'Key generated! Put this key into your GitHub account now.'
    File.open(PUBLIC_KEYFILE, 'r') do |public_keyfile|
        puts
	puts public_keyfile.read
	puts
	wait
    end
end

# Set up NeoVim
puts_divider('Neovim Configuration')

# Install neovim and missing jemalloc dependency (as of time of script creation)
puts_output 'Installing Neovim...'
dnf_y('install neovim jemalloc')

# Configure Neovim
CONFIG_DIR = rel_to_home('.config')
NVIM_DIR = File.join(CONFIG_DIR, 'nvim')
FileUtils::mkdir_p CONFIG_DIR
if File.exist?(NVIM_DIR) && File.directory?(NVIM_DIR)
    puts_output 'A Neovim configuration already exists. Skipping.'
else
    puts_output 'Cloning Neovim RC...'
    system "git clone --recursive git@github.com:Bourg/neovim.git #{NVIM_DIR}"
    puts_output 'Neovim RC successfully cloned!'
end

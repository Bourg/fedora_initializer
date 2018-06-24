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

class InitializationTask
  def apply
    pre
    if should?
      execute
    else
      noop
    end
    post
  end

  def should?
    true
  end

  def pre
  end

  def post
  end

  def execute
  end

  def noop
  end
end

class FileMissingTask < InitializationTask
  def initialize(file, startup, noop, action)
    @file = file
    @startup = startup
    @noop = noop
    @action = action
  end

  def should?
    !File.exists?(@file) 
  end

  def pre
    puts_output @startup
  end

  def noop
    puts_output @noop
  end

  def execute
    @action.call(@file)
  end
end

puts_divider 'Now bootstrapped into Ruby!'

puts_divider 'Web Browser Installation'
dnf_y('install fedora-workstation-repositories')
dnf_y('config-manager --set-enabled google-chrome')
dnf_y('install google-chrome-stable')

puts_divider "SSH Configuration"

PUBLIC_KEYFILE = rel_to_home('.ssh/id_rsa.pub')
FileMissingTask.new(
  PUBLIC_KEYFILE,
  'Configuring SSH key...',
  'An SSH key already exists. Skipping...',
  Proc.new do
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
).apply()

# Set up NeoVim
puts_divider('Neovim Configuration')

# Install
puts_output 'Installing Neovim...'
dnf_y('install neovim jemalloc')

# Configure Neovim
CONFIG_DIR = rel_to_home('.config')
NVIM_DIR = File.join(CONFIG_DIR, 'nvim')

FileMissingTask.new(
  NVIM_DIR,
  'Cloning Neovim configuration...',
  'A Neovim configuration already exists. Skipping...',
  Proc.new do 
    puts_output 'Cloning Neovim RC...'
    FileUtils::mkdir_p CONFIG_DIR
    system "git clone --recursive git@github.com:Bourg/neovim.git #{NVIM_DIR}"
    puts_output 'Neovim RC successfully cloned!'
  end).apply()

puts_divider('i3wm Configuration')

# Set up i3wm
puts_output 'Installing i3'
dnf_y "install i3 i3status dmenu i3lock feh"

puts_output 'Configuring i3'
I3_DIR = File.join(CONFIG_DIR, 'i3')
FileMissingTask.new(
  I3_DIR,
  'Cloning i3 configuration...',
  'An i3 configuration already exists. Skipping...',
  Proc.new do
    puts_output 'Cloning i3 config...'
    FileUtils::mkdir_p CONFIG_DIR
    system "git clone git@github.com:Bourg/i3.git #{I3_DIR}"
    puts_output 'i3 config successfully cloned!'
  end
).apply()

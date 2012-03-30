require 'formula'

class MySqlInstalled < Requirement
  def message; <<-EOS.undent
    MySQL is required to install.

    You can install this with Homebrew using:
      brew install mysql

    If you plan to install mysql-odbc-connector as universal (32- and 64-bit),
    install MySQL using:
      brew install mysql --universal

    Or, you can use an official installer from:
      http://dev.mysql.com/downloads/mysql/
    EOS
  end
  def satisfied?
    which 'mysql_config'
  end
  def fatal?
    true
  end
end

class MysqlConnectorOdbc < Formula
  homepage 'http://dev.mysql.com/doc/refman/5.1/en/connector-odbc.html'
  url 'http://mysql.mirror.iweb.ca/Downloads/Connector-ODBC/5.1/mysql-connector-odbc-5.1.11-src.tar.gz'
  sha1 '46aeaf721eddedaed239c4a688faee1990dcec62'

  # Won't compile against mysql-connector-c, as the C connector exports an API version
  # that causes issues with how "my_free" is declared
  depends_on MySqlInstalled.new
  depends_on 'cmake' => :build

  def options
    [['--universal', "Make mysql-connector-odbc a universal binary"]]
  end

  def install
    args = ["-DCMAKE_INSTALL_PREFIX=#{prefix}"]
    args << "-DCMAKE_OSX_ARCHITECTURES='i386;x86_64'" if ARGV.build_universal?
    ENV['MYSQL_DIR'] = HOMEBREW_PREFIX
    system 'cmake', ".", *args
    fix_goofy_link_file_error
    system 'make install'
  end

  def fix_goofy_link_file_error
    # fixes linker error on linking up libmyodbc5.so on lion
    # I have no idea why the -L/usr/local/lib -lmysqlclient_r doesn't do the
    # trick. Can't use homebrew's patch system since it applies before link.txt
    # exists; it gets generated by cmake.
    #
    # see http://bugs.mysql.com/bug.php?id=63302
    #
    link_file_name = "driver/CMakeFiles/myodbc5.dir/link.txt"
    old_link = File.read link_file_name
    File.open link_file_name, 'w' do |f|
      f.puts "#{old_link.strip} #{HOMEBREW_PREFIX}/lib/libmysqlclient_r.a"
    end
  end
end
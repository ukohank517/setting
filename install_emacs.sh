sudo yum -y install gcc make ncurses-devel
wget http://ftp.jaist.ac.jp/pub/GNU/emacs/emacs-24.5.tar.gz
tar xvf emacs-24.5.tar.gz
cd emacs-24.5
./configure
#  ./configure --prefix=$HOME/local
sudo make
sudo make install

#!/usr/bin/env bash

# names of latest versions of each package
export VERSION_PCRE=pcre-8.38
export VERSION_OPENSSL=openssl-1.0.2d
export VERSION_NGINX=nginx-$1

# URLs to the source directories
export SOURCE_OPENSSL=https://www.openssl.org/source/
export SOURCE_PCRE=ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/
export SOURCE_NGINX=http://nginx.org/download/

# Create build folder
mkdir build

# grab the source files
wget -P ./build $SOURCE_PCRE$VERSION_PCRE.tar.gz
wget -P ./build $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz --no-check-certificate
wget -P ./build $SOURCE_NGINX$VERSION_NGINX.tar.gz

# expand the source files
cd build
tar xzf $VERSION_NGINX.tar.gz
tar xzf $VERSION_OPENSSL.tar.gz
tar xzf $VERSION_PCRE.tar.gz
cd ../

# set where OpenSSL and nginx will be built
export BPATH=$(pwd)/build
export STATICLIBSSL="$BPATH/staticlibssl"

# build static openssl
cd $BPATH/$VERSION_OPENSSL
rm -rf "$STATICLIBSSL"
mkdir "$STATICLIBSSL"
make clean
./config --prefix=$STATICLIBSSL no-shared \
&& make depend \
&& make \
&& make install_sw

# build nginx, with various modules included/excluded
cd $BPATH/$VERSION_NGINX
mkdir -p $BPATH/nginx
./configure --with-cc-opt="-I $STATICLIBSSL/include -I/usr/include" \
--with-ld-opt="-L $STATICLIBSSL/lib -Wl,-rpath -lssl -lcrypto -ldl -lz" \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--pid-path=/var/run/nginx.pid \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--with-pcre=$BPATH/$VERSION_PCRE \
--with-http_ssl_module \
--with-http_v2_module \
--with-file-aio \
--with-ipv6 \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--without-mail_pop3_module \
--without-mail_smtp_module \
--without-mail_imap_module \
&& make && make install

echo "All done.";

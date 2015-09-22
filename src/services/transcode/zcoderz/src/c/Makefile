AR=ar
CC=gcc
EMAR=emar
EMCC=emcc
CFLAGS=-I./ -I$(LIBVPX) -I$(LIBVPX)vpx -I$(LIBVPX)vp8 -I$(LIBVPX)vp9 -I$(LIBVPX)vp10 -I$(LIBYUV)include
COPT=O3
EXP_FUNCS='["_create_stream","_stream_width","_stream_height","_destroy_stream","_stream_get_buff_fill","_stream_flush","_stream_seek","_stream_write","_stream_write_chunk","_stream_parse","_stream_parse_yuv"]'

LIBVPX=/opt/vendor/libvpx/
LIBYUV=/opt/vendor/libyuv/
LIBOPUS=/opt/vendor/libopus/.lib/

all: clean javascript

##
##
native: libzcoderz.a

##
##
# $(LIBVPX)vpx_ports/mem_ops.h
libzcoderz_test: libzcoderz.a
	$(CC) -$(COPT) -static -o ./build/zcoderz $(CFLAGS) -L./build zcoderz_test.c -lzcoderz -lm -lc

libzcoderz.a: zcoderz.c /opt/vendor/libvpx/libvpx.a
	mkdir -p build
	$(CC) --version
	$(AR) -x /opt/vendor/libvpx/libvpx.a
	mv *.o build
	$(CC) -$(COPT) -c $(CFLAGS) $(LIBVPX)ivfdec.c -o ./build/ivfdec.o
	$(CC) -$(COPT) -c $(CFLAGS) $(LIBVPX)tools_common.c -o ./build/tools_common.o
	$(CC) -$(COPT) -c $(CFLAGS) $(LIBVPX)video_stream_reader.c -o ./build/video_stream_reader.o
	$(CC) -$(COPT) -c $(CFLAGS) zcoderz.c -o ./build/zcoderz.o
	$(AR) -rcs ./build/libzcoderz.a ./build/*.o
	# $(CC) -O3 -static -L$(LIBVPX) ./build/zcoderz.bc ./build/ivfdec.bc\
	# 				./build/tools_common.bc ./build/video_reader.bc\
	# 				-o ./build/libzcoderz -lvpx

##
##
javascript: libzcoderz_test.js

##
##
libzcoderz_test.js: libzcoderz.bc
	$(EMCC) -$(COPT) -c $(CFLAGS) zcoderz_test.c -o ./build/zcoderz_test.bc
	$(EMCC) -$(COPT) -static -L$(LIBVPX) -L$(LIBYUV) -L$(LIBOPUS) ./build/zcoderz_test.bc ./build/libzcoderz.bc\
					-o ./build/libzcoderz_test.js -lvpx -lyuv -lopus

##
##
libzcoderz.bc: zcoderz.c /opt/vendor/libvpx/libvpx.a
	mkdir -p build
	$(EMCC) --version
	$(EMCC) -$(COPT) -c $(CFLAGS) $(LIBVPX)ivfdec.c -o ./build/ivfdec.bc
	$(EMCC) -$(COPT) -c $(CFLAGS) $(LIBVPX)tools_common.c -o ./build/tools_common.bc
	$(EMCC) -$(COPT) -c $(CFLAGS) $(LIBVPX)video_stream_reader.c -o ./build/video_stream_reader.bc
	$(EMCC) -$(COPT) -c $(CFLAGS) zcoderz.c -o ./build/zcoderz.bc
	$(EMCC) -$(COPT) -static -L$(LIBVPX) -L$(LIBYUV) -L$(LIBOPUS) ./build/zcoderz.bc ./build/ivfdec.bc\
					./build/tools_common.bc ./build/video_stream_reader.bc\
					-o ./build/libzcoderz.bc -lvpx -lyuv -lopus
	$(EMCC) -$(COPT) -static -L$(LIBVPX) -s EXPORTED_FUNCTIONS=$(EXP_FUNCS)\
					./build/libzcoderz.bc -o ./build/libzcoderz.js

clean:
	rm -rf build

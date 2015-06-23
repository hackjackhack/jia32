DISTORM_GIT_URL = git://github.com/gdabah/distorm

all:
	([ ! -d distorm ] && \
		git clone $(DISTORM_GIT_URL) distorm ) || true
	make -C distorm/make/linux
	cp distorm/make/linux/libdistorm3.so .

update:
	([ ! -d distorm ] && \
		git clone $(DISTORM_GIT_URL) distorm ) || \
		(cd distorm && \
		git pull --ff-only)
	make -C distorm/make/linux
	cp distorm/make/linux/libdistorm3.so .

clean:
	rm -f *.so
	make -C distorm/make/linux clean

superclean:
	rm -rf *.so distorm/

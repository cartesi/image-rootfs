.PHONY: build push

build:
	docker build -t cartesi/image-rootfs:latest .

push:
	docker push cartesi/image-rootfs:latest

run:
	docker run -it --rm cartesi/image-rootfs:latest

share:
	docker run -it --rm -v `pwd`:/opt/riscv/host cartesi/image-rootfs:latest

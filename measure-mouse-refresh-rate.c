#include <string.h>
#include <stdio.h>
#include <linux/input.h>
#include <fcntl.h>
#include <signal.h>
#include <getopt.h>
#include <unistd.h>

#define EVENTS 50
#define HZ_LIST 64

typedef struct event_s {
	int fd;
	int hz[HZ_LIST];
	int count;
	int avghz;
	double prvtime;
	char name[128];
} event_t;

int quit = 0;

void sigint() {
	quit = 1;
}

int main(int argc, char *argv[]) {
	int optch;
	int i;
	event_t events[EVENTS];
	int verbose = 1;

	while((optch = getopt(argc, argv, "hn")) != -1) {
		switch(optch) {
			case('h'):
				printf("Usage: %s [-n|-h]\n", argv[0]);
				printf("-n     nonverbose\n");
				printf("-h     help\n");
				return 0;
				break;
			case('n'):
				verbose = 0;
				break;
		}
	}

    if(geteuid() != 0) {
        printf("%s must be used as superuser\n", argv[0]);
        return 1;
    }

	signal(SIGINT, sigint);

	printf("Press CTRL-C to exit.\n\n");

	memset(events, 0, sizeof(events));

	// List input devices
	for(i = 0; i < EVENTS; i++) {
		char device[19];

		sprintf(device, "/dev/input/event%i", i);
		events[i].fd = open(device, O_RDONLY);
		
		if(events[i].fd != -1) {
			ioctl(events[i].fd, EVIOCGNAME(sizeof(events[i].name)), events[i].name);
			if(verbose) printf("event%i: %s\n", i, events[i].name);
		}
	}

	while(!quit) {
		fd_set set;

		FD_ZERO(&set);

		for(i = 0; i < EVENTS; i++) {
			if(events[i].fd != -1) {
				FD_SET(events[i].fd, &set);
			}
		}

		if(select(FD_SETSIZE, &set, NULL, NULL, NULL) > 0) {
			int bytes;
			struct input_event event;

			for(i = 0; i < EVENTS; i++) {
				if(events[i].fd == -1 || !FD_ISSET(events[i].fd, &set)) {
					continue;
				}

				bytes = read(events[i].fd, &event, sizeof(event));

				if(bytes != sizeof(event)) {
					continue;
				}

				if(event.type == EV_REL || event.type == EV_ABS) {
					double time;
					int hz;

					time = event.time.tv_sec * 1000 + event.time.tv_usec / 1000;
					hz = 1000 / (time - events[i].prvtime);

					if(hz > 0) {
						int j;

						events[i].count++;
						events[i].hz[events[i].count & (HZ_LIST - 1)] = hz;

						events[i].avghz = 0;

						for(j = 0; j < HZ_LIST; j++) {
							events[i].avghz += events[i].hz[j];
						}

						events[i].avghz /= (events[i].count > HZ_LIST) ? HZ_LIST : events[i].count;

						if(verbose) printf("%s: Latest % 5iHz, Average % 5iHz\n", events[i].name, hz, events[i].avghz);
					}

					events[i].prvtime = time;
				}
			}
		}
	}

	for(i = 0; i < EVENTS; i++) {
		if(events[i].fd != -1) {
			if (events[i].avghz != 0) {
				printf("\nAverage for %s: % 5iHz\n", events[i].name, events[i].avghz);
			}
			close(events[i].fd);
		}
	}

	return 0;
}

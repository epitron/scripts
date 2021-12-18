/*
MPB(1)                      General Commands Manual                     MPB(1)


NAME
       mpb - more progress bar
       https://github.com/lecram/mpb

SYNOPSIS
       mpb [-o] [-v] [-s] [-wWIDTH] [TOTAL]

DESCRIPTION
       Show progress of lines read from stdin in stderr.

OPTIONS
       -o     output stdin to stdout

       -v     show current line

       -s     show activity spinner

       -wWIDTH
              set width of progress bar (default = 32)

       TOTAL  number of lines expected to be read until completion of task
              if TOTAL is not given or it is zero, the progress bar will not
              be shown

EXAMPLES
       Use seq(1) to test drive mpb:
              $ n=5000; seq $n | mpb -vsw50 $n

       Show path of file currently being extracted by tar(1) (without progress
       bar):
              $ tar vxf foo.tgz | mpb -v

       Pre-compute the number of files in archive to add extraction progress
       bar:
              $ f=foo.tgz; n=$(tar tf $f | wc -l); tar vxf $f | mpb -v $n


                                  2020-04-02                            MPB(1)
*/

#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#define DEFAULT_WIDTH   32
#define LINE_MAX        (1 << 12)

static char spinchars[] = "|/-\\";
static unsigned spinindex = 0;
static char line[LINE_MAX];
static unsigned lastfill = UINT_MAX;
static unsigned lastpercent = 101;

void
print_progress(unsigned width, unsigned percent, int showbar, int showspinner, int showline)
{
    unsigned i, fill;
    fill = percent * width / 100;
    if (showspinner) {
        if (percent == 100)
            spinindex = 0;
        fprintf(stderr, " (%c)", spinchars[spinindex++]);
        spinindex %= sizeof(spinchars) - 1;
    }
    if (showbar) {
        if (fill != lastfill) {
            if (lastfill > width)
                lastfill = 0;
            fprintf(stderr, " [");
            if (lastfill)
                fprintf(stderr, "\x1B[%uC", lastfill);
            for (i = lastfill; i < fill; i++)
                fputc('#', stderr);
            if (!percent) {
                for (; i < width; i++)
                    fputc('-', stderr);
            } else {
                if (fill < width)
                    fprintf(stderr, "\x1B[%uC", width - fill);
            }
            lastfill = fill;
        } else {
            fprintf(stderr, "\x1B[%uC", width + 2);
        }
        if (percent != lastpercent) {
            fprintf(stderr, "] %3u%%", percent);
            lastpercent = percent;
        }
        fprintf(stderr, "\r");
        if (showline)
            fprintf(stderr, "\x1B[B%s\x1B[K\r\x1B[A", line);
    } else if (showline) {
        fprintf(stderr, " %s\x1B[K", line);
    }
    fprintf(stderr, "\r");
    fflush(stderr);
}

int
main(int argc, char *argv[])
{
    unsigned long count;
    unsigned percent;
    int i;
    char *c;
    char *arg;
    char *argtotal = NULL;
    int opt_showbar;
    int opt_showline = 0;
    int opt_showspinner = 0;
    int opt_output = 0;
    unsigned opt_width = DEFAULT_WIDTH;
    unsigned long total = 0;
    for (i = 1; i < argc; i++) {
        arg = argv[i];
        if (*arg == '-') {
            while (*(++arg)) {
                switch (*arg) {
                case 'v':
                    opt_showline = 1;
                    break;
                case 's':
                    opt_showspinner = 1;
                    break;
                case 'o':
                    opt_output = 1;
                    break;
                case 'w':
                    opt_width = (unsigned) strtol(arg+1, &arg, 10);
                    if (opt_width)
                        arg--;
                    else
                        opt_width = DEFAULT_WIDTH;
                    break;
                default:
                    fprintf(stderr, "%s: error: unknown option '-%c'\n", argv[0], *arg);
                    return 1;
                }
            }
        } else {
            argtotal = arg;
        }
    }
    if (argtotal != NULL)
        total = (unsigned) atol(argtotal);
    opt_showbar = total > 0;
    if (opt_showbar)
        fprintf(stderr, "\n\x1B[A");
    print_progress(opt_width, 0, opt_showbar, opt_showspinner, 0);
    count = 0;
    while (fgets(line, LINE_MAX, stdin) != NULL) {
        if (opt_output)
            printf(line);
        for (c = line; *c && *c != '\n'; c++) ;
        *c = '\0';
        if (count < total)
            count++;
        if (opt_showbar)
            percent = count * 100 / total;
        print_progress(opt_width, percent, opt_showbar, opt_showspinner, opt_showline);
    }
    print_progress(opt_width, 100, opt_showbar, opt_showspinner, 0);
    fputs("\x1B[B\x1B[2K\x1B[A\n", stderr);
    return 0;
}

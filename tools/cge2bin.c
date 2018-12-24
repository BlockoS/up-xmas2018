#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <getopt.h>
#include <errno.h>
#include <string.h>

#define MAX_WIDTH 40
#define MAX_HEIGHT 25

void usage() {
    fprintf(stderr, "cge2bin -x U -y V [--width|-w] N [--height|-h] M input output\n"); 
}

int main(int argc, char **argv) {
    struct option long_options[] = {
        {"width", required_argument, 0, 'w'},
        {"height", required_argument, 0, 'h'}
    };
    char options[] = "w:h:x:y:";
    int option_index;
    int c;
    
    int x = 0;
    int y = 0;
    int w = MAX_WIDTH;
    int h = MAX_HEIGHT;
    
    while(1) {
        option_index = 0;
        c = getopt_long (argc, argv, options, long_options, &option_index);
        if(c < 0) {
            break;
        }
        switch(c) {
            case 'x':
                x = atoi(optarg);
                break;
            case 'y':
                y = atoi(optarg);
                break;
            case 'w':
                w = atoi(optarg);
                break;
            case 'h':
                h = atoi(optarg);
                break;
            default:
                usage();
                return EXIT_FAILURE;
        }
    }
    
    if ((argc - optind) != 2) {
        usage();
        return EXIT_FAILURE;
    }

    if(x > MAX_WIDTH) { 
        fprintf(stderr, "invalid x %d (max %d)\n", x, MAX_WIDTH);
        return EXIT_FAILURE;
    }
    if(y > MAX_HEIGHT) { 
        fprintf(stderr, "invalid y %d (max %d)\n", y, MAX_HEIGHT);
        return EXIT_FAILURE;
    }
    if(w <= 0) {
        fprintf(stderr, "invalid width %d (min 0)\n", w);
        return EXIT_FAILURE;    
    }
    if(h <= 0) {
        fprintf(stderr, "invalid height %d (min 0)\n", h);
        return EXIT_FAILURE;    
    }

    FILE *input = fopen(argv[optind], "rb");
    if(!input) {
        fprintf(stderr, "failed to open %s: %s\n", argv[optind], strerror(errno));
        return EXIT_FAILURE;
    }	
    FILE *output = fopen(argv[optind+1], "wb");
    if(!output) {
        fprintf(stderr, "failed to open %s: %s\n", argv[optind+1], strerror(errno));
        fclose(input);
        return EXIT_FAILURE;
    }	

    if(w > MAX_WIDTH) { w = MAX_WIDTH; }
    if(h > MAX_HEIGHT) { h = MAX_HEIGHT; }
    if(x < 0) { x = 0; }
    if(y < 0) { y = 0; }
    if((x+w) > MAX_WIDTH) { w = MAX_WIDTH-x; }
    if((y+h) > MAX_HEIGHT) { h = MAX_HEIGHT-x; }

    printf("source x=%d y=%d w=%d h=%d\n", x, y, w, h);

    int i, j;
	uint8_t *attr = (uint8_t*)malloc(MAX_WIDTH*MAX_HEIGHT);
    uint8_t *color = (uint8_t*)malloc(MAX_WIDTH*MAX_HEIGHT);

	for(j=MAX_HEIGHT-1; j>=0; j--) {
	    for(i=0; i<MAX_WIDTH; i++) {
		    fscanf(input,"%d,", &c);
		    attr[i+(j*MAX_WIDTH)] = c & 0xff;	
		    color[i+(j*MAX_WIDTH)] = (c > 255) ? 0x80 : 0x00;
	    }
    }
	for(j=MAX_HEIGHT-1; j>=0; j--) {
	    for(i=0; i<MAX_WIDTH; i++) {
		    fscanf(input,"%d,", &c);
		    color[i+(j*MAX_WIDTH)] |= (c&0x07)<<4;
	    }
    }
	for(j=MAX_HEIGHT-1; j>=0; j--) {
	    for(i=0; i<MAX_WIDTH; i++) {
		    fscanf(input,"%d,", &c);
		    color[i+(j*MAX_WIDTH)] |= (c&0x07);
	    }
    }
	fclose(input);

    int offset = x + (y*MAX_WIDTH);
    for(int j=0; j<h; j++) {
        fwrite(color + offset, 1, w, output);
        offset += MAX_WIDTH;
    }
    offset = x + (y*MAX_WIDTH);
    for(int j=0; j<h; j++) {
        fwrite(attr + offset, 1, w, output);
        offset += MAX_WIDTH;
    }

    fclose(output);

    free(attr);
    free(color);

    return EXIT_SUCCESS;
}
#if 0
	FILE *output = fopen(argv[2], "wb");

    int offset;
    offset = 0;
    for(int j=0; j<height; j++) {
        fwrite(color + offset + 9, 1, 9, output);
        fwrite(color + offset, 1, 9, output);
        offset += 40;        
    }
    offset = 0;
    for(int j=0; j<height; j++) {
        fwrite(attr + offset + 9, 1, 9, output);
        fwrite(attr + offset, 1, 9, output);
        offset += 40;        
    }

	fclose(output);

	free(color);
	free(attr);	
	return EXIT_SUCCESS;
}
#endif

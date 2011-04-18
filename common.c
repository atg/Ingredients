#import <stdio.h>
#import <sys/types.h>
#import <string.h>

/*
 * find the last occurrance of find in string
 *
 * Copyright 1998-2002 University of Illinois Board of Trustees
 * Copyright 1998-2002 Mark D. Roth
 * All rights reserved.
 *
 * strrstr.c - strrstr() function for compatibility library
 *
 * Mark D. Roth <roth@uiuc.edu>
 * Campus Information Technologies and Educational Services
 * University of Illinois at Urbana-Champaign
 */
const char *common_strrstr(const char *string, const char *find) {
  size_t stringlen, findlen;
  char *cp;
  findlen = strlen(find);
  stringlen = strlen(string);
  if (findlen > stringlen)
    return NULL;
  for (cp = (char*)string + stringlen - findlen; cp >= string; cp--)
    if (strncmp(cp, find, findlen) == 0)
      return cp;
  return NULL;
}
// TODO: check if the system have strrstr and use that instead

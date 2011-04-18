#ifndef COMMON_H_
#define COMMON_H_

// Foundation is nice to have
#ifdef __OBJC__
  #import <Foundation/Foundation.h>
#endif

// Filename macro
#ifndef __FILENAME__
  #define __FILENAME__ ((strrchr(__FILE__, '/') ?: __FILE__ - 1) + 1)
#endif
#define __SRC_FILENAME__ \
  ((common_strrstr(__FILE__, "/src/") ?: __FILE__ - 1) + 1)

// log info, warning and error message
// DLOG(format[, ...]) -- log a debug message
#if defined(__OBJC__)
  #define _LOG(prefixch, fmt, ...) \
      NSLog((NSString*)(CFSTR("%c [%s:%d] " fmt)), prefixch, \
            __SRC_FILENAME__, __LINE__, ##__VA_ARGS__)
#else
  #define _LOG(prefixch, fmt, ...) \
      fprintf(stderr, "%c [%s:%d] " fmt, prefixch, \
              __SRC_FILENAME__, __LINE__, ##__VA_ARGS__)
#endif
#ifdef LOG_SILENT
  #define ILOG(...) do{}while(0)
#else
  #define ILOG(...) _LOG('I', __VA_ARGS__)
#endif
#define WLOG(...) _LOG('W', __VA_ARGS__)
#define ELOG(...) _LOG('E', __VA_ARGS__)

// Debug/development utilities
#if !defined(NDEBUG)
  #ifndef _DEBUG
    #define _DEBUG 1
  #endif
  // shorthand to include and evaluate <x> only for debug builds
  #define IFDEBUG(x) do{ x }while(0)
  #define DLOG(...) _LOG('D', __VA_ARGS__)
  #define DLOG_TRACE() _LOG('T', "%s", __func__)
  // log an expression
  #ifdef __OBJC__
    // trace "<ObjCClass: 0xAddress> selector"
    #define DLOG_TRACE_M() \
      _LOG('T', "%@ %@", self, NSStringFromSelector(_cmd));
    
    NSString *VTPG_DDToStringFromTypeAndValue(const char *tc, void *v);
    #define DLOG_EXPR(_X_) do{\
      __typeof__(_X_) _Y_ = (_X_);\
      const char * _TYPE_CODE_ = @encode(__typeof__(_X_));\
      NSString *_STR_ = VTPG_DDToStringFromTypeAndValue(_TYPE_CODE_, &_Y_);\
      if(_STR_){\
        NSLog(@"X [%s:%d] %s = %@", __SRC_FILENAME__, __LINE__, #_X_, _STR_);\
      }else{\
        NSLog(@"Unknown _TYPE_CODE_: %s for expression %s in function %s, file %s, line %d",\
              _TYPE_CODE_, #_X_, __func__, __SRC_FILENAME__, __LINE__);\
      }}while(0)
  #else // __OBJC__
    #define DLOG_EXPR(_X_) fprintf(stderr, "%s [%d] X [%s:%d] %s = %s\n",\
                              __FILENAME__, getpid(), __SRC_FILENAME__, __LINE__, \
                              #_X_, "<TODO:common.h>")
    // TODO eval expression ---------------^
  #endif // __OBJC__
#else // !defined(NDEBUG)
  #define IFDEBUG(x)     do{}while(0)
  #define DLOG(...)      do{}while(0)
  #define DLOG_TRACE()   do{}while(0)
  #define DLOG_EXPR(...) do{}while(0)
#endif // !defined(NDEBUG)

// libbase compatible assertion macros
#define DCHECK assert
#define DCHECK_OP(op, val1, val2) assert((val1) op (val2))
#define DCHECK_EQ(val1, val2) DCHECK_OP(==, val1, val2)
#define DCHECK_NE(val1, val2) DCHECK_OP(!=, val1, val2)
#define DCHECK_LE(val1, val2) DCHECK_OP(<=, val1, val2)
#define DCHECK_LT(val1, val2) DCHECK_OP(< , val1, val2)
#define DCHECK_GE(val1, val2) DCHECK_OP(>=, val1, val2)
#define DCHECK_GT(val1, val2) DCHECK_OP(> , val1, val2)

// log an error and exit when reaching unimplemented parts
#import <err.h>
#define NOTIMPLEMENTED() errx(4, "[not implemented] %s (%s:%d)", \
                              __PRETTY_FUNCTION__, __SRC_FILENAME__, __LINE__)

#define NOTREACHED() assert(false && "Should not have been reached")

// strrstr
#ifdef __cplusplus
extern "C" {
#endif
const char *common_strrstr(const char *string, const char *find);
#ifdef __cplusplus
}
#endif

// utils
#ifdef __OBJC__
  // exchange dst with src, retaining src and safely releasing old object.
  //   id old = ct_objc_xch(&foo_, [NSColor redColor]);
  static inline id ct_objc_xch(id *dst, id src) {
    id old = *dst;
    *dst = src;
    if (old) [old release];
    if (src) [src retain];
    return old;
  }
#endif // __OBJC__

#endif // COMMON_H_

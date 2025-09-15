#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "Make NBIS's wsq_decode_mem Thread Safe",
  desc: [Make it thread-safe by modifying the source code],
  date: "2025-09-15",
  tags: (
    blog-tags.programming,
    blog-tags.clang,
  ),
)

Recently, I'm working on a project to decode WSQ files which requires to use NBIS's wsq_decode_mem function. But I found that the function is not thread-safe. After coding with AI, I made several changes to the source code to make it thread-safe.

= Problem

The function is not thread-safe because it uses several global static variables to store the state of the decoder. When my program is running in parallel, the variables will be overwritten by different threads, causing the decoder to crash.

= Solution

Modify source code to use thread-local variables.

In `imgtools/include/wsq.h` insert,

```c
#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
#define WSQ_TLS _Thread_local
#elif defined(__GNUC__) || defined(__clang__)
#define WSQ_TLS __thread
#else
#define WSQ_TLS
#warning "No thread-local storage; WSQ decode won't be thread-safe."
#endif
```

In `imgtools/include/wsq.h`, replace the global static variables with thread-local variables,

```c
extern int debug;
extern WSQ_TLS QUANT_VALS quant_vals;
extern WSQ_TLS W_TREE w_tree[];
extern WSQ_TLS Q_TREE q_tree[];
extern WSQ_TLS DTT_TABLE dtt_table;
extern WSQ_TLS DQT_TABLE dqt_table;
extern WSQ_TLS DHT_TABLE dht_table[];
extern WSQ_TLS FRM_HEADER_WSQ frm_header_wsq;

/* hifilt/lofilt are read-only constants, so no need to change TLS */
extern float hifilt[];
extern float lofilt[];
```

In `imgtools/src/lib/wsq/globals.c`, replace the global static definitions with thread-local variables,

```c
#ifdef TARGET_OS
   WSQ_TLS QUANT_VALS quant_vals;

   WSQ_TLS W_TREE w_tree[W_TREELEN];

   WSQ_TLS Q_TREE q_tree[Q_TREELEN];

   WSQ_TLS DTT_TABLE dtt_table;

   WSQ_TLS DQT_TABLE dqt_table;

   WSQ_TLS DHT_TABLE dht_table[MAX_DHT_TABLES];

   WSQ_TLS FRM_HEADER_WSQ frm_header_wsq;
#else
   WSQ_TLS QUANT_VALS quant_vals = {};

   WSQ_TLS W_TREE w_tree[W_TREELEN] = {};

   WSQ_TLS Q_TREE q_tree[Q_TREELEN] = {};

   WSQ_TLS DTT_TABLE dtt_table = {};

   WSQ_TLS DQT_TABLE dqt_table = {};

   WSQ_TLS DHT_TABLE dht_table[MAX_DHT_TABLES] = {};

   WSQ_TLS FRM_HEADER_WSQ frm_header_wsq = {};
#endif
```

In `imgtools/src/lib/wsq/decoder.c`, replace static variables with thread-local variables in `nextbits_wsq` and `getc_nextbits_wsq`,

```c
static WSQ_TLS unsigned char code;   /*next byte of data*/
static WSQ_TLS unsigned char code2;  /*stuffed byte of data*/
unsigned short bits, tbits;  /*bits of current data byte requested*/
int bits_needed;     /*additional bits required to finish request*/

                          /*used to "mask out" n number of
                            bits from data stream*/
static unsigned char bit_mask[9] = {0x00,0x01,0x03,0x07,0x0f,
                                    0x1f,0x3f,0x7f,0xff};
```

`bit_mask` is a read-only constant, so no need to change TLS.

The `code` and `code2` variables are used to store the next byte of data and the stuffed byte of data, respectively. After changing TLS, the variables will be stored in the thread-local storage, so they will not be overwritten by different threads.

= Result

Multi-thread problem solved :-)

After modifying these variables, the `wsq_decode_mem` function is now thread-safe, so I built it and used it in my project with multiple threads, turned out to be working fine.

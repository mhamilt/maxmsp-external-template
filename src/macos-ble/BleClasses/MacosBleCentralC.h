/*
  C Bridge for CoreBluetooth Central on macOS
 
 Bridging techinque by Rob Napier. https://github.com/rnapier
 */
#pragma once
#ifdef __OBJC__
#import "MacosBleCentral.h"
#endif
typedef const void MacosBleCentralC; // 'const void *' is more CF-like, but either is fine

MacosBleCentralC* newMacosBleCentralC(void);
void MacosBleCentralC_startScan(MacosBleCentralC *t);
void MacosBleCentralC_stopScan(MacosBleCentralC *t);
float MacosBleCentralC_getLatestValue(MacosBleCentralC *t);
void MacosBleCentralC_release(MacosBleCentralC *t);

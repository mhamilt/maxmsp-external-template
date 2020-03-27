/*
    C Bridge for CoreBluetooth Central on macOS
*/

#import "MacosBleCentralC.h"

//------------------------------------------------------------------------------
MacosBleCentralC* newMacosBleCentralC(void)
{
    return CFBridgingRetain([MacosBleCentral new]);
}
//------------------------------------------------------------------------------
void MacosBleCentralC_startScan(MacosBleCentralC *t)
{
    [(__bridge MacosBleCentral *)t startScan];
}
//------------------------------------------------------------------------------
void MacosBleCentralC_stopScan(MacosBleCentralC *t)
{
    [(__bridge MacosBleCentral *)t stopScan];
}
//------------------------------------------------------------------------------
float MacosBleCentralC_getLatestValue(MacosBleCentralC *t)
{
    return [(__bridge MacosBleCentral *)t latestValue];
}
//------------------------------------------------------------------------------
void MacosBleCentralC_release(MacosBleCentralC *t)
{
    CFRelease(t);
}
//------------------------------------------------------------------------------

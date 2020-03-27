//------------------------------------------------------------------------------
#import "MacosBleCentral.h"
//------------------------------------------------------------------------------
@implementation MacosBleCentral
//------------------------------------------------------------------------------
@synthesize discoveredPeripherals;
//------------------------------------------------------------------------------
- (instancetype)init
{
    dispatch_queue_t newQueue = dispatch_queue_create("max_masp_ble",  DISPATCH_QUEUE_SERIAL);
    return [self initWithQueue:newQueue];
}
//------------------------------------------------------------------------------
- (instancetype)initWithQueue: (dispatch_queue_t) centralDelegateQueue
{
    return [self initWithQueue: centralDelegateQueue
//                 serviceToScan: nil
//          characteristicToRead: nil];
                 serviceToScan: [CBUUID UUIDWithString: @"29D7544B-6870-45A4-BB7E-D981535F4525"]
          characteristicToRead: [CBUUID UUIDWithString: @"B81672D5-396B-4803-82C2-029D34319015"]];
}

- (instancetype)initWithQueue: (dispatch_queue_t) centralDelegateQueue
                serviceToScan: (CBUUID *) scanServiceId
         characteristicToRead: (CBUUID *) characteristicId
{
    self = [super init];
    if (self)
    {
        post("start BLE");
        self.discoveredPeripherals = [NSMutableArray array];
        _count=0;
        _latestValue = 0;
        shouldScan = true;
        _bleQueue = centralDelegateQueue;
        serviceUuid = scanServiceId;
        characteristicUuid = characteristicId;
        _manager = [[CBCentralManager alloc] initWithDelegate: self
                                                        queue: _bleQueue];
    }
    return self;
}

//------------------------------------------------------------------------------
- (void)dealloc
{    
    [_manager stopScan];
    //    [_manager dealloc]
//    [super dealloc];
}

//------------------------------------------------------------------------------
#pragma mark Manager Methods

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)aPeripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSMutableArray *peripherals =  [self mutableArrayValueForKey:@"discoveredPeripherals"];
    const char* deviceName = [[aPeripheral name] cStringUsingEncoding:NSASCIIStringEncoding];
    if (deviceName)
        printf("Found: %s\n", deviceName);
    
    if ([[aPeripheral name] isEqualToString: @"BaronVonTigglestest"])
    {
        [self connectToPeripheral: aPeripheral];
    }
    
    if( ![self.discoveredPeripherals containsObject:aPeripheral] && deviceName)
    {
        [peripherals addObject:aPeripheral];
        [self.discoveredPeripherals addObject:aPeripheral];
//        [self connectToPeripheral: aPeripheral];
    }
}

//------------------------------------------------------------------------------
- (void) centralManager: (CBCentralManager *)central
   didConnectPeripheral: (CBPeripheral *)aPeripheral
{
    post("Connected to iPhone\n");
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
}

- (void) centralManager:(CBCentralManager *)central
 didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
    
    [_manager stopScan];
    
    /* If there are any known devices, automatically connect to it.*/
    if([peripherals count] >=1)
    {
        peripheral = [peripherals objectAtIndex:0];
        [_manager connectPeripheral:peripheral
                            options:nil];
    }
}

//------------------------------------------------------------------------------
- (void)centralManagerDidUpdateState:(CBCentralManager *)manager
{
    if ([manager state] == CBManagerStatePoweredOn && shouldScan)
    {
        [self startScan];
    }
}
//------------------------------------------------------------------------------
// Invoked whenever an existing connection with the peripheral is torn down.
- (void) centralManager: (CBCentralManager *)central
didDisconnectPeripheral: (CBPeripheral *)aPeripheral
                  error: (NSError *)error
{
    post("didDisconnectPeripheral\n");
}
//------------------------------------------------------------------------------
/// Invoked whenever the central manager fails to create a connection with the peripheral.
- (void) centralManager: (CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral
                  error:(NSError *)error
{
     post("didFailToConnectPeripheral\n");
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
}
//------------------------------------------------------------------------------
- (void) startScan
{
    post("Start scanning\n");
    
    if (!serviceUuid)
    {
        [_manager scanForPeripheralsWithServices: nil
                                         options: nil];
    }
    else
    {
        [_manager scanForPeripheralsWithServices: [NSArray arrayWithObject: serviceUuid]
                                         options: nil];
    }
}

- (void) connectToPeripheral: (CBPeripheral *)aPeripheral
{
    post("connect");
    [_manager stopScan];
    peripheral = aPeripheral;
    NSDictionary *connectOptions = @{
        CBConnectPeripheralOptionNotifyOnConnectionKey: @YES,
        CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES,
        CBConnectPeripheralOptionNotifyOnNotificationKey: @YES,
        //        CBConnectPeripheralOptionEnableTransportBridgingKey:,
        //        CBConnectPeripheralOptionRequiresANCS:,
        CBConnectPeripheralOptionStartDelayKey: @0
    };
    [_manager connectPeripheral:peripheral options:connectOptions];
}
//------------------------------------------------------------------------------
#pragma mark Peripheral Methods

// Invoked upon completion of a -[discoverServices:] request.
// Discover available characteristics on interested services
- (void) peripheral: (CBPeripheral *)aPeripheral
didDiscoverServices:(NSError *)error
{
    post("didDiscoverServices\n");
    if (error)
    {
        post("error\n");
    }
    for (CBService *aService in aPeripheral.services)
    {
        
#if DEBUG_MODE
        NSLog(@"Service found with UUID: %@", aService.UUID);
        post("Service found with UUID: %s", [[aService.UUID UUIDString] cStringUsingEncoding:NSASCIIStringEncoding]);
#endif
//        [aPeripheral discoverCharacteristics:@[characteristicUuid]
//                                  forService:aService];
        [aPeripheral discoverCharacteristics: nil
                                  forService: aService];
    }
}
//------------------------------------------------------------------------------

// Invoked upon completion of a -[discoverCharacteristics:forService:] request.
// Perform appropriate operations on interested characteristics
- (void) peripheral: (CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    post("didDiscoverCharacteristicsForService\n");
    
    if (error)
    {
        post("error\n");
    }
    for (CBCharacteristic *aChar in service.characteristics)
    {
#if DEBUG_MODE
        NSLog(@"Service: %@ with Char: %@", [aChar service].UUID, aChar.UUID);
#endif
        if (aChar.properties & CBCharacteristicPropertyRead)
        {
            [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
            //                [aPeripheral readValueForCharacteristic:aChar];
            //                [aPeripheral readValueForDescriptor:nil]
        }
    }
}
//------------------------------------------------------------------------------

// Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
- (void) peripheral: (CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    post("didUpdateValueForCharacteristic\n");
    [self printCharacteristicData:characteristic];
}

- (void) printCharacteristicData: (CBCharacteristic *)characteristic
{
    post("new float\n");
#if DEBUG_MODE
    NSLog(@"Read Characteristics: %@", characteristic.UUID);
    NSLog(@"%@", [characteristic description]);
#endif
    NSData * updatedValue = characteristic.value;
//    _latestValue = [[[NSString alloc] initWithUTF8String:(char*)updatedValue.bytes] floatValue];
//    post("new float: %.5f\n",_latestValue);
//    printf("%s\n",(char*)updatedValue.bytes);
}

- (void) peripheral: (CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBDescriptor *)descriptor error:(NSError *)error
{
    
}

- (void)peripheral: (CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
}
- (void)peripheral: (CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
//    exit(0);
    post("Service Modified\n");
    [_manager cancelPeripheralConnection:peripheral];
    [self startScan];
}
//------------------------------------------------------------------------------
@end

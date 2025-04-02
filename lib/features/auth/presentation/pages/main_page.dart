import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController serverUrlController =
      TextEditingController(text: "http://intra.luxrobo.net:7880");
  // ble 전용 컨트롤러
  final TextEditingController bleQueryController = TextEditingController();

  String serverUrl = '';
  bool isConnecting = false;
  String connectionStatus = ''; // "Connected" 또는 "Disconnected"

  // 기존 모듈 API 응답 (네트워크 탭 전용)
  Map<String, dynamic>? moduleStatus;

  // ble 전용 상태 변수
  bool showBleInput = false;
  Map<String, dynamic>? bleStatus;
  bool isBleLoading = false;
  bool isModuleLoading = false;
  String? currentModule;
  int _moduleRequestId = 0;

  String appliedServerUrl = '';

  int _selectedIndex = 0; // 0: 네트워크, 1: 조명, 2: 관리자 사이트
  bool showDimmingInput = false;
  bool showOtaButtons = false;
  List<Map<String, dynamic>>? dimmingStatus;
  bool isDimmingLoading = false;
  final TextEditingController dimmingQueryController = TextEditingController();
  List<Map<String, dynamic>>? otaList;
  bool isOtaListLoading = false;
  List<Map<String, dynamic>>? uploadProgressList;
  bool isUploadProgressLoading = false;
  final TextEditingController uploadProgressQueryController =
      TextEditingController();
  List<Map<String, dynamic>>? otaInfoList;
  bool isOtaInfoLoading = false;
  final TextEditingController otaInfoQueryController = TextEditingController();
  final TextEditingController otaInitQueryController = TextEditingController();
  final TextEditingController otaInitModIdController = TextEditingController();
  final TextEditingController otaInitTypeController = TextEditingController();

  // Add new state variables for CCTV status
  List<Map<String, dynamic>>? cctvStatusList;
  bool isCctvStatusLoading = false;

  // 관리자 사이트 하위 탭 선택 (lights: 조명 제어, emergency: 비상호출 시스템)
  String adminSubTab = "lights";
  final TextEditingController parkingLocationController =
      TextEditingController();
  List<Map<String, dynamic>>? lightingControlData;
  Map<String, dynamic>? dimmingConfig;

  Future<void> applyServerUrl() async {
    setState(() {
      isConnecting = true;
      serverUrl = serverUrlController.text;
      moduleStatus = null; // 초기화
      bleStatus = null;
      connectionStatus = '';
      showBleInput = false;
    });

    try {
      // API 호출 시뮬레이션; 실제 호출 로직으로 교체 가능
      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        setState(() {
          connectionStatus = '서버 연결 중';
          appliedServerUrl = serverUrlController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server URL applied successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply server URL: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isConnecting = false;
        });
      }
    }
  }

  Future<void> checkNetworkModuleStatus(String module) async {
    if (appliedServerUrl.isEmpty) return;
    setState(() {
      moduleStatus = null;
      currentModule = module;
      isModuleLoading = true;
      _moduleRequestId++;
    });
    final int requestId = _moduleRequestId;
    try {
      final url = '$appliedServerUrl/api/dev/parking-lights/network/status';
      final response = await http.get(Uri.parse(url));
      if (requestId != _moduleRequestId) {
        // This response is outdated; clear stale data and exit
        setState(() {
          moduleStatus = null;
          isModuleLoading = false;
        });
        return;
      }
      if (response.statusCode == 200) {
        setState(() {
          moduleStatus = json.decode(response.body);
          isModuleLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Failed to fetch module statuses (Code: ${response.statusCode})')));
        setState(() {
          isModuleLoading = false;
        });
      }
    } catch (e) {
      if (requestId != _moduleRequestId) {
        setState(() {
          moduleStatus = null;
          isModuleLoading = false;
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching module statuses: $e')));
      setState(() {
        isModuleLoading = false;
      });
    }
  }

  Future<void> checkBleStatus() async {
    if (serverUrl.isEmpty) return;
    setState(() {
      isBleLoading = true;
      bleStatus = null;
    });
    final url =
        '$serverUrl/api/dev/parking-lights/ble?cctvName=${Uri.encodeComponent(bleQueryController.text)}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          bleStatus = json.decode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to fetch BLE status (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isBleLoading = false;
      });
    }
  }

  Future<void> checkDimmingStatus() async {
    if (appliedServerUrl.isEmpty) return;
    setState(() {
      isDimmingLoading = true;
      dimmingStatus = null;
    });
    final url =
        '$appliedServerUrl/api/dev/parking-lights/dimming?cctvName=${Uri.encodeComponent(dimmingQueryController.text)}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          dimmingStatus = List<Map<String, dynamic>>.from(data);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to fetch dimming status (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching dimming status: $e')),
      );
    } finally {
      setState(() {
        isDimmingLoading = false;
      });
    }
  }

  Future<void> fetchOtaFileList() async {
    if (appliedServerUrl.isEmpty) return;
    setState(() {
      isOtaListLoading = true;
      otaList = null;
    });
    final url = '$appliedServerUrl/api/dev/parking-lights/ota-list';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          otaList = List<Map<String, dynamic>>.from(data);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to fetch OTA file list (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching OTA file list: $e')),
      );
    } finally {
      setState(() {
        isOtaListLoading = false;
      });
    }
  }

  Future<void> fetchUploadProgress() async {
    if (appliedServerUrl.isEmpty) return;
    setState(() {
      isUploadProgressLoading = true;
      uploadProgressList = null;
    });
    final url = '$appliedServerUrl/api/dev/parking-lights/ota/';
    try {
      print(url);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'c0f0de79-55f3-419b-88ea-6dde435acb35',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          uploadProgressList = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to fetch upload progress (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching upload progress: $e')),
      );
    } finally {
      setState(() {
        isUploadProgressLoading = false;
      });
    }
  }

  Future<void> fetchOtaInfo() async {
    if (appliedServerUrl.isEmpty) return;
    setState(() {
      isOtaInfoLoading = true;
      otaInfoList = null;
    });
    final url =
        '$appliedServerUrl/api/dev/parking-lights/sys?cctvName=${Uri.encodeComponent(otaInfoQueryController.text)}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          otaInfoList = List<Map<String, dynamic>>.from(data);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to fetch OTA info (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching OTA info: $e')),
      );
    } finally {
      setState(() {
        isOtaInfoLoading = false;
      });
    }
  }

  Future<void> handleOtaInit() async {
    if (appliedServerUrl.isEmpty) return;
    final url =
        '$appliedServerUrl/api/dev/parking-lights/sys/${Uri.encodeComponent(otaInitQueryController.text)}';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'c0f0de79-55f3-419b-88ea-6dde435acb35',
        },
        body: json.encode([
          {
            "modId": int.parse(otaInitModIdController.text),
            "type": otaInitTypeController.text
          }
        ]),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Success'),
              content: Text(response.body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to initialize OTA (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing OTA: $e')),
      );
    }
  }

  Future<void> fetchLightingControl() async {
    if (appliedServerUrl.isEmpty) return;
    final location = parkingLocationController.text;
    final url =
        '$appliedServerUrl/api/admin/status/location?location=${Uri.encodeComponent(location)}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'c0f0de79-55f3-419b-88ea-6dde435acb35'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          lightingControlData = [
            {
              "lightName": "통로등",
              "mode": data['aisle']['mode'],
              "state": data['aisle']['state']
            },
            {
              "lightName": "만공차등",
              "mode": data['parking']['mode'],
              "state": data['parking']['state']
            },
            {
              "lightName": "충돌방지등",
              "mode": data['caution']['mode'],
              "state": data['caution']['state']
            },
            {
              "lightName": "실내경광등",
              "mode": data['warning']['mode'],
              "state": data['warning']['state']
            },
          ];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('조회 실패 (Code: ${response.statusCode})')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }

  Future<void> fetchDimmingConfig() async {
    if (appliedServerUrl.isEmpty) return;
    final location = parkingLocationController.text;
    final url =
        '$appliedServerUrl/api/admin/dimming/location?location=${Uri.encodeComponent(location)}';
    try {
      print(url);
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'c0f0de79-55f3-419b-88ea-6dde435acb35'
        }, // Added API key here
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          dimmingConfig = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to fetch dimming config (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching dimming config: $e')),
      );
    }
  }

  // ble 응답을 테이블 형식으로 표시: 두 컬럼, Field와 Value
  Widget _buildBleStatusTable() {
    if (bleStatus == null) return Container();
    List<DataRow> rows = [];
    bleStatus!.forEach((key, value) {
      rows.add(DataRow(cells: [
        DataCell(Text(key.toString())),
        DataCell(Text(value.toString())),
      ]));
    });
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8.0,
        horizontalMargin: 8.0,
        dataRowHeight: 40.0,
        headingRowHeight: 40.0,
        columns: const [
          DataColumn(label: Text('Field')),
          DataColumn(label: Text('Value')),
        ],
        rows: rows,
      ),
    );
  }

  // 네트워크 탭의 테이블 형태 (다른 모듈 등) - 기존 모듈용
  Widget _buildModuleStatusListView() {
    if (moduleStatus == null || moduleStatus!['lightStatusList'] == null) {
      return Container();
    }
    List<dynamic> list = moduleStatus!['lightStatusList'];
    List<DataRow> rows = [];
    for (var item in list) {
      String cctvName = item['cctvName'] ?? '';
      List<dynamic> lightStatusList = item['lightStatus'] ?? [];
      for (var light in lightStatusList) {
        rows.add(DataRow(cells: [
          DataCell(Text(cctvName)),
          DataCell(Text(light['modId'].toString())),
          DataCell(Text(light['status'] ?? '')),
          DataCell(Text(light['type'] ?? '')),
        ]));
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8.0,
        horizontalMargin: 8.0,
        dataRowHeight: 40.0,
        headingRowHeight: 40.0,
        columns: const [
          DataColumn(label: Text('CCTV Name')),
          DataColumn(label: Text('Mod ID')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Type')),
        ],
        rows: rows,
      ),
    );
  }

  Widget _buildModuleStatusView() {
    if (moduleStatus == null) return Container();
    List<dynamic> lightStatusList = moduleStatus!['lightStatusList'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('CCTV Name')),
          DataColumn(label: Text('Mod ID')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Type')),
        ],
        rows: lightStatusList.expand((cctv) {
          String cctvName = cctv['cctvName'] ?? '';
          List<dynamic> lights = cctv['lightStatus'] ?? [];
          return lights.map<DataRow>((light) {
            return DataRow(
              cells: [
                DataCell(Text(cctvName)),
                DataCell(Text(light['modId'].toString())),
                DataCell(Text(light['status'] ?? '')),
                DataCell(Text(light['type'] ?? '')),
              ],
            );
          });
        }).toList(),
      ),
    );
  }

  Widget _buildAllModuleStatusTable() {
    if (moduleStatus == null || moduleStatus!['lightStatusList'] == null)
      return Container();
    List<dynamic> list = moduleStatus!['lightStatusList'];
    List<DataRow> rows = [];
    for (var item in list) {
      String cctvName = item['cctvName'] ?? '';
      List<dynamic> lightStatusList = item['lightStatus'] ?? [];
      for (var light in lightStatusList) {
        rows.add(DataRow(cells: [
          DataCell(Text(cctvName)),
          DataCell(Text(light['modId'].toString())),
          DataCell(Text(light['status'] ?? '')),
          DataCell(Text(light['type'] ?? '')),
        ]));
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 25.0,
        horizontalMargin: 8.0,
        dataRowHeight: 40.0,
        headingRowHeight: 40.0,
        columns: const [
          DataColumn(label: Text('CCTV Name')),
          DataColumn(label: Text('Mod ID')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Type')),
        ],
        rows: rows,
      ),
    );
  }

  Widget _buildDimmingStatusTable() {
    if (moduleStatus == null || moduleStatus!['lightStatusList'] == null)
      return Container();
    List<dynamic> list = moduleStatus!['lightStatusList'];
    List<DataRow> rows = [];
    for (var item in list) {
      String cctvName = item['cctvName'] ?? '';
      List<dynamic> lightStatusList = item['lightStatus'] ?? [];
      for (var light in lightStatusList) {
        if (light['type'] == 'dimming') {
          rows.add(DataRow(cells: [
            DataCell(Text(cctvName)),
            DataCell(Text(light['modId'].toString())),
            DataCell(Text(light['status'] ?? '')),
            DataCell(Text(light['type'] ?? '')),
          ]));
        }
      }
    }
    return rows.isNotEmpty
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 8.0,
              horizontalMargin: 8.0,
              dataRowHeight: 40.0,
              headingRowHeight: 40.0,
              columns: const [
                DataColumn(label: Text('CCTV Name')),
                DataColumn(label: Text('Mod ID')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Type')),
              ],
              rows: rows,
            ),
          )
        : Center(child: Text('No dimming module data found'));
  }

  Widget _buildOtaStatusTable() {
    if (moduleStatus == null || moduleStatus!['lightStatusList'] == null)
      return Container();
    List<dynamic> list = moduleStatus!['lightStatusList'];
    List<DataRow> rows = [];
    for (var item in list) {
      String cctvName = item['cctvName'] ?? '';
      List<dynamic> lightStatusList = item['lightStatus'] ?? [];
      for (var light in lightStatusList) {
        if (light['type'] == 'ota') {
          rows.add(DataRow(cells: [
            DataCell(Text(cctvName)),
            DataCell(Text(light['modId'].toString())),
            DataCell(Text(light['status'] ?? '')),
            DataCell(Text(light['type'] ?? '')),
          ]));
        }
      }
    }
    return rows.isNotEmpty
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 8.0,
              horizontalMargin: 8.0,
              dataRowHeight: 40.0,
              headingRowHeight: 40.0,
              columns: const [
                DataColumn(label: Text('CCTV Name')),
                DataColumn(label: Text('Mod ID')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Type')),
              ],
              rows: rows,
            ),
          )
        : Center(child: Text('No OTA module data found'));
  }

  // Add new function to fetch CCTV status
  Future<void> fetchCctvStatus() async {
    if (appliedServerUrl.isEmpty) return;
    setState(() {
      isCctvStatusLoading = true;
      cctvStatusList = null;
    });
    final url = '$appliedServerUrl/api/dev/test/cctv';
    try {
      final response = await http.get(
        Uri.parse(url),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cctvStatusList = List<Map<String, dynamic>>.from(data);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to fetch CCTV status (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching CCTV status: $e')),
      );
    } finally {
      setState(() {
        isCctvStatusLoading = false;
      });
    }
  }

  // Add new widget to build CCTV status table
  Widget _buildCctvStatusTable() {
    if (cctvStatusList == null || cctvStatusList!.isEmpty)
      return Center(child: Text('No Data'));
    print(cctvStatusList);
    return DataTable(
      columnSpacing: 12.0,
      horizontalMargin: 12.0,
      dataRowHeight: 40.0,
      headingRowHeight: 40.0,
      columns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('IP Address')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Monitoring')),
        DataColumn(label: Text('Monitored At')),
      ],
      rows: cctvStatusList!.map((item) {
        if (item is Map<String, dynamic>) {
          return DataRow(
            cells: [
              DataCell(Text(item['name']?.toString() ?? '')),
              DataCell(Text(item['ipAddr']?.toString() ?? '')),
              DataCell(Text(item['status']?.toString() ?? '')),
              DataCell(Text(item['monitoring']?.toString() ?? '')),
              DataCell(Text(item['monitoredAt']?.toString() ?? '')),
            ],
          );
        } else {
          return const DataRow(
            cells: [
              DataCell(Text('Invalid')),
              DataCell(Text('Invalid')),
              DataCell(Text('Invalid')),
              DataCell(Text('Invalid')),
              DataCell(Text('Invalid')),
            ],
          );
        }
      }).toList(),
    );
  }

  // 상단 고정 헤더 영역 (서버 URL 입력 및 적용)
  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isConnecting)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('서버 URL 연결 중...'),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: serverUrlController,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'Enter server URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isConnecting ? null : applyServerUrl,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: const Color.fromARGB(255, 219, 111, 140),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('서버 연결'),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (connectionStatus.isNotEmpty)
              Center(
                child: Text(
                  connectionStatus,
                  style: TextStyle(
                    color: connectionStatus == 'Disconnected'
                        ? Colors.red
                        : Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 선택된 탭에 따른 가운데 내용 영역
  Widget _buildBodyContent() {
    if (_selectedIndex == 0) {
      return Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    moduleStatus = null;
                    bleStatus = null;
                    dimmingStatus = null;
                    showBleInput = false;
                    showDimmingInput = false;
                  });
                  await checkNetworkModuleStatus("all");
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                child: Text('모든 모듈 상태 확인'),
              ),
              ElevatedButton(
                onPressed: () {
                  // ble 버튼을 누르면 ble 관련 입력 UI 표시
                  setState(() {
                    showBleInput = true;
                    bleStatus = null;
                    moduleStatus = null; // clear the network table
                    dimmingStatus = null;
                    showDimmingInput = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                child: Text('ble'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Update dimming button to show dimming input UI
                  setState(() {
                    showDimmingInput = true;
                    showBleInput = false;
                    moduleStatus = null;
                    bleStatus = null;
                    dimmingStatus = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                child: Text('dimming'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    moduleStatus = null;
                    bleStatus = null;
                    dimmingStatus = null;
                    showBleInput = false;
                    showDimmingInput = false;
                    showOtaButtons = true;
                  });
                  await checkNetworkModuleStatus("ota");
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                child: Text('ota'),
              ),
            ],
          ),
          Container(
            height: 1,
            color: Colors.grey,
            margin: EdgeInsets.symmetric(vertical: 8),
          ),
          SizedBox(height: 20),
          if (showBleInput)
            Column(
              children: [
                TextField(
                  controller: bleQueryController,
                  decoration: InputDecoration(
                    labelText: 'CCTV Name for BLE',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: checkBleStatus,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: Text('조회'),
                ),
                SizedBox(height: 8),
                if (isBleLoading) CircularProgressIndicator(),
                if (bleStatus != null) _buildBleStatusTable(),
              ],
            )
          else if (showDimmingInput)
            Column(
              children: [
                TextField(
                  controller: dimmingQueryController,
                  decoration: InputDecoration(
                    labelText: 'CCTV Name for Dimming',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: checkDimmingStatus,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: Text('조회'),
                ),
                SizedBox(height: 8),
                if (isDimmingLoading) CircularProgressIndicator(),
                if (dimmingStatus != null) _buildDimmingQueryTable(),
              ],
            )
          else
            Expanded(
              child: isModuleLoading
                  ? Center(child: CircularProgressIndicator())
                  : (moduleStatus != null
                      ? (currentModule == "all"
                          ? _buildAllModuleStatusTable()
                          : currentModule == "ota"
                              ? (showOtaButtons
                                  ? Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  otaInfoList = null;
                                                  uploadProgressList = null;
                                                });
                                                fetchOtaFileList();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 8),
                                                textStyle:
                                                    TextStyle(fontSize: 12),
                                              ),
                                              child: Text('OTA File List'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  otaList = null;
                                                  uploadProgressList = null;
                                                  otaInfoList = null;
                                                });
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title:
                                                        Text('Enter CCTV Name'),
                                                    content: TextField(
                                                      controller:
                                                          otaInfoQueryController,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: 'CCTV Name',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                          fetchOtaInfo();
                                                        },
                                                        child: Text('Query'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 8),
                                                textStyle:
                                                    TextStyle(fontSize: 12),
                                              ),
                                              child: Text('OTA Info'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  otaList = null;
                                                  uploadProgressList = null;
                                                  otaInfoList = null;
                                                });
                                                fetchUploadProgress();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 8),
                                                textStyle:
                                                    TextStyle(fontSize: 12),
                                              ),
                                              child: Text('Upload Progress'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  otaList = null;
                                                  uploadProgressList = null;
                                                  otaInfoList = null;
                                                });
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text(
                                                        'Enter OTA Init Details'),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        TextField(
                                                          controller:
                                                              otaInitQueryController,
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                'CCTV Name',
                                                            border:
                                                                OutlineInputBorder(),
                                                          ),
                                                        ),
                                                        SizedBox(height: 8),
                                                        TextField(
                                                          controller:
                                                              otaInitModIdController,
                                                          decoration:
                                                              InputDecoration(
                                                            labelText: 'Mod ID',
                                                            border:
                                                                OutlineInputBorder(),
                                                          ),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                        ),
                                                        SizedBox(height: 8),
                                                        TextField(
                                                          controller:
                                                              otaInitTypeController,
                                                          decoration:
                                                              InputDecoration(
                                                            labelText: 'Type',
                                                            border:
                                                                OutlineInputBorder(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                          handleOtaInit();
                                                        },
                                                        child: Text('Apply'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 8),
                                                textStyle:
                                                    TextStyle(fontSize: 12),
                                              ),
                                              child: Text('OTA Init'),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        if (isOtaListLoading)
                                          CircularProgressIndicator(),
                                        if (otaList != null)
                                          _buildOtaFileListTable(),
                                        if (isUploadProgressLoading)
                                          CircularProgressIndicator(),
                                        if (uploadProgressList != null)
                                          _buildUploadProgressTable(),
                                        if (isOtaInfoLoading)
                                          CircularProgressIndicator(),
                                        if (otaInfoList != null)
                                          _buildOtaInfoTable(),
                                      ],
                                    )
                                  : _buildOtaStatusTable())
                              : currentModule == "cctv"
                                  ? _buildCctvStatusTable()
                                  : Container())
                      : Center(child: Text('네트워크 상태 데이터를 불러오세요'))),
            ),
        ],
      );
    } else if (_selectedIndex == 1) {
      // 조명 탭
      return Center(
        child: Text(
          '조명 페이지',
          style: TextStyle(fontSize: 20),
        ),
      );
    } else if (_selectedIndex == 2) {
      // 관리자 사이트 탭
      return _buildAdminContent();
    }
    return Container();
  }

  // 3a. New widget to build the dimming query table
  Widget _buildDimmingQueryTable() {
    if (dimmingStatus == null) return Container();
    return ListView.builder(
      shrinkWrap: true,
      itemCount: dimmingStatus!.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> item = dimmingStatus![index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            title: Text('Module ID: ${item["modId"]}'),
            subtitle: Text(
                'Mode: ${item["mode"]} • Value: ${item["value"]} • Duration: ${item["duration"]} • Count: ${item["durCount"]}'),
          ),
        );
      },
    );
  }

  Widget _buildOtaFileListTable() {
    if (otaList == null) return Container();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8.0,
        horizontalMargin: 8.0,
        dataRowHeight: 40.0,
        headingRowHeight: 40.0,
        columns: const [
          DataColumn(label: Text('File')),
          DataColumn(label: Text('Dev Type')),
          DataColumn(label: Text('Uploaded')),
          DataColumn(label: Text('Version')),
        ],
        rows: otaList!.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item['file']?.toString() ?? '')),
              DataCell(Text(item['devType']?.toString() ?? '')),
              DataCell(Text(item['uploaded']?.toString() ?? '')),
              DataCell(Text(item['version']?.toString() ?? '')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUploadProgressTable() {
    if (uploadProgressList == null) return Container();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8.0,
        horizontalMargin: 8.0,
        dataRowHeight: 40.0,
        headingRowHeight: 40.0,
        columns: const [
          DataColumn(label: Text('CCTV Name')),
          DataColumn(label: Text('Mod ID')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Version')),
          DataColumn(label: Text('File')),
        ],
        rows: uploadProgressList!.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item['cctvName']?.toString() ?? '')),
              DataCell(Text(item['modId']?.toString() ?? '')),
              DataCell(Text(item['string']?.toString() ?? '')),
              DataCell(Text(item['version']?.toString() ?? '')),
              DataCell(Text(item['file']?.toString() ?? '')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOtaInfoTable() {
    if (otaInfoList == null) return Container();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8.0,
        horizontalMargin: 8.0,
        dataRowHeight: 40.0,
        headingRowHeight: 40.0,
        columns: const [
          DataColumn(label: Text('Dimming')),
          DataColumn(label: Text('Mod ID')),
          DataColumn(label: Text('Mod Type')),
          DataColumn(label: Text('Version')),
        ],
        rows: otaInfoList!.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item['dimming']?.toString() ?? '')),
              DataCell(Text(item['modId']?.toString() ?? '')),
              DataCell(Text(item['modType']?.toString() ?? '')),
              DataCell(Text(item['version']?.toString() ?? '')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdminContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    adminSubTab = "lights";
                    lightingControlData = null;
                    parkingLocationController.clear();
                  });
                },
                child: Text('조명 제어'),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    adminSubTab = "emergency";
                  });
                },
                child: Text('비상호출 시스템'),
              ),
            ],
          ),
          SizedBox(height: 16),
          adminSubTab == "lights"
              ? _buildLightingControlPanel()
              : _buildEmergencySystem(),
        ],
      ),
    );
  }

  Widget _buildLightingControlPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: parkingLocationController,
                decoration: InputDecoration(
                  labelText: '주차장 위치',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // 조회 버튼 클릭 시 조명 제어 데이터와 기본 조명값 조회
                fetchLightingControl();
                fetchDimmingConfig();
              },
              child: Text('조회'),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (lightingControlData != null)
          Column(
            children: lightingControlData!.expand((data) {
              final List<Widget> widgets = [];
              widgets.add(
                Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(data['lightName'])),
                        Expanded(
                          flex: 2,
                          child: DropdownButton<String>(
                            value: (['auto', 'manual']
                                    .contains(data['mode']?.toString())
                                ? data['mode']?.toString()
                                : 'auto'),
                            items: ['auto', 'manual'].map((value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                data['mode'] = newValue;
                              });
                            },
                          ),
                        ),
                        if (data['mode'] == 'manual')
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Text('On'),
                                Switch(
                                  value: data['state'] == 'on',
                                  onChanged: (bool newVal) {
                                    setState(() {
                                      data['state'] = newVal ? 'on' : 'off';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                            flex: 2, child: Text('현재 상태: ${data['state']}')),
                      ],
                    ),
                  ),
                ),
              );
              if (data['lightName'] == '실내경광등' && dimmingConfig != null) {
                widgets.add(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final String location =
                                parkingLocationController.text;
                            if (location.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("주차장 위치를 입력하세요.")));
                              return;
                            }
                            final String url =
                                '$appliedServerUrl/api/admin/status/location/${Uri.encodeComponent(location)}';
                            final Map<String, dynamic> requestBody = {
                              "aisle": {
                                "mode": data['mode'],
                                "state": data['state']
                              },
                              "caution": {
                                "mode": data['mode'],
                                "state": data['state']
                              },
                              "parking": {
                                "mode": data['mode'],
                                "state": data['state']
                              },
                              "warning": {
                                "mode": data['mode'],
                                "state": data['state']
                              }
                            };
                            try {
                              final response = await http.post(Uri.parse(url),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization':
                                        'c0f0de79-55f3-419b-88ea-6dde435acb35'
                                  },
                                  body: json.encode(requestBody));
                              if (response.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text("조명 상태가 성공적으로 수정되었습니다.")));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        "조명 상태 수정 실패 (Code: ${response.statusCode})")));
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("오류가 발생했습니다: $e")));
                            }
                          },
                          child: Text("조명 상태 수정"),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '기본 조명값',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ),
                      Row(
                        children: [
                          Text('Dim Min : '),
                          Container(
                            width: 60,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: Text(
                              '${dimmingConfig!['dimMin']}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Dim Max : '),
                          Container(
                            width: 60,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: Text(
                              '${dimmingConfig!['dimMax']}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            final TextEditingController controllerMin =
                                TextEditingController(
                                    text: dimmingConfig!['dimMin'].toString());
                            final TextEditingController controllerMax =
                                TextEditingController(
                                    text: dimmingConfig!['dimMax'].toString());
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Edit Dimming Values'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: controllerMin,
                                      keyboardType: TextInputType.number,
                                      decoration:
                                          InputDecoration(labelText: 'dimMin'),
                                    ),
                                    TextField(
                                      controller: controllerMax,
                                      keyboardType: TextInputType.number,
                                      decoration:
                                          InputDecoration(labelText: 'dimMax'),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        dimmingConfig!['dimMin'] =
                                            int.tryParse(controllerMin.text) ??
                                                dimmingConfig!['dimMin'];
                                        dimmingConfig!['dimMax'] =
                                            int.tryParse(controllerMax.text) ??
                                                dimmingConfig!['dimMax'];
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Text('Save'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text('조명값 수정'),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return widgets;
            }).toList(),
          ),
        SizedBox(height: 16),
        /*
        ElevatedButton(
          onPressed: () {
            print("Lighting Control Applied: $lightingControlData, Dimming Config: $dimmingConfig");
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('조명 설정이 적용되었습니다.')));
          },
          child: Text('적용하기'),
        ),
        */
      ],
    );
  }

  Widget _buildEmergencySystem() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () async {
                if (appliedServerUrl.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('서버 URL을 입력해주세요')),
                  );
                  return;
                }
                final TextEditingController cctvNameController =
                    TextEditingController();
                final TextEditingController deviceTypeController =
                    TextEditingController(text: "OnePassKey");
                final TextEditingController masterCodeController =
                    TextEditingController(text: "E8-54-B1-93-A1-56");

                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('SOS 벨 Push 요청'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: cctvNameController,
                          decoration: InputDecoration(
                            labelText: 'CCTV Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: deviceTypeController,
                          decoration: InputDecoration(
                            labelText: 'Device Type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: masterCodeController,
                          decoration: InputDecoration(
                            labelText: 'Master Code',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('취소'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (cctvNameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('CCTV 이름을 입력해주세요')),
                            );
                            return;
                          }
                          try {
                            final response = await http.post(
                              Uri.parse(
                                  '$appliedServerUrl/api/dev/test/sos-push/${Uri.encodeComponent(cctvNameController.text)}'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization':
                                    'c0f0de79-55f3-419b-88ea-6dde435acb35',
                              },
                              body: json.encode({
                                "deviceType": deviceTypeController.text,
                                "masterCode": masterCodeController.text
                              }),
                            );
                            if (response.statusCode == 200) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('SOS 벨 Push 성공')),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'SOS 벨 Push 실패 (Code: ${response.statusCode})')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('오류 발생: $e')),
                            );
                          }
                        },
                        child: Text('요청'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 230, 190, 215),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'SOS 벨 Push',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (appliedServerUrl.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('서버 URL을 입력해주세요')),
                  );
                  return;
                }
                final TextEditingController cctvNameController =
                    TextEditingController();
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('SOS 벨 Pop 요청'),
                    content: TextField(
                      controller: cctvNameController,
                      decoration: InputDecoration(
                        labelText: 'CCTV Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('취소'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (cctvNameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('CCTV 이름을 입력해주세요')),
                            );
                            return;
                          }
                          try {
                            final response = await http.post(
                              Uri.parse(
                                  '$appliedServerUrl/api/dev/test/sos-pop/${Uri.encodeComponent(cctvNameController.text)}'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization':
                                    'c0f0de79-55f3-419b-88ea-6dde435acb35',
                              },
                            );
                            if (response.statusCode == 200) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('SOS 벨 Pop 성공')),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'SOS 벨 Pop 실패 (Code: ${response.statusCode})')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('오류 발생: $e')),
                            );
                          }
                        },
                        child: Text('요청'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'SOS 벨 Pop',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 고정 Header, 가운데 동적으로 변경되는 Body, 하단 고정 BottomNavigationBar
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(child: _buildBodyContent()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            // 다른 탭 전환 시 ble 입력창 숨김
            if (index != 0) showBleInput = false;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.network_check), label: '네트워크'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: '조명'),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings), label: '관리자 사이트'),
        ],
      ),
    );
  }
}

/// Common OBD-II Diagnostic Trouble Codes relevant to two-wheelers,
/// mapped to plain-language complaints a mechanic/rider understands.
/// This is a starter set — extend as real-world scan data comes in.
class DtcInfo {
  final String code;
  final String title;
  final String plainLanguage;
  final String severity; // "low", "medium", "high"

  const DtcInfo(this.code, this.title, this.plainLanguage, this.severity);
}

final Map<String, DtcInfo> dtcDatabase = {
  'P0011': const DtcInfo('P0011', 'Intake Camshaft Timing Over-Advanced',
      'Engine timing issue — may cause rough idle or poor pickup', 'medium'),
  'P0100': const DtcInfo('P0100', 'Mass Air Flow Circuit Malfunction',
      'Air flow sensor problem — check for bad mileage/rough running', 'medium'),
  'P0113': const DtcInfo('P0113', 'Intake Air Temp Circuit High',
      'Air temperature sensor fault', 'low'),
  'P0130': const DtcInfo('P0130', 'O2 Sensor Circuit Malfunction',
      'Oxygen sensor issue — affects fuel mixture, mileage drops', 'medium'),
  'P0171': const DtcInfo('P0171', 'System Too Lean',
      'Fuel mixture too lean — check for air leak or injector clog', 'medium'),
  'P0172': const DtcInfo('P0172', 'System Too Rich',
      'Fuel mixture too rich — check injector, may smell fuel/poor mileage',
      'medium'),
  'P0217': const DtcInfo('P0217', 'Engine Overtemp Condition',
      'Engine running hot — check coolant/oil level immediately', 'high'),
  'P0300': const DtcInfo('P0300', 'Random/Multiple Cylinder Misfire',
      'Engine misfiring — check plug, coil, injector', 'high'),
  'P0301': const DtcInfo('P0301', 'Cylinder 1 Misfire Detected',
      'Misfire in cylinder 1 — check spark plug/coil', 'high'),
  'P0335': const DtcInfo('P0335', 'Crankshaft Position Sensor Circuit',
      'Crank sensor fault — bike may not start or stall suddenly', 'high'),
  'P0340': const DtcInfo('P0340', 'Camshaft Position Sensor Circuit',
      'Cam sensor fault — starting/running issue', 'medium'),
  'P0420': const DtcInfo('P0420', 'Catalyst System Efficiency Below Threshold',
      'Catalytic converter underperforming — emissions issue', 'low'),
  'P0500': const DtcInfo('P0500', 'Vehicle Speed Sensor Malfunction',
      'Speed sensor fault — speedometer/ABS may misbehave', 'medium'),
  'P0562': const DtcInfo('P0562', 'System Voltage Low',
      'Battery/charging voltage low — check battery, stator, rectifier',
      'high'),
  'P0563': const DtcInfo('P0563', 'System Voltage High',
      'Overcharging — check regulator/rectifier', 'high'),
  'P0600': const DtcInfo('P0600', 'Serial Communication Link',
      'ECU communication fault', 'medium'),
  'P0605': const DtcInfo('P0605', 'ECM ROM Error',
      'ECU internal fault — may need ECU replacement/reflash', 'high'),
};

/// Looks up a DTC; falls back to a generic entry if not in the local DB
/// so the app never shows a blank complaint.
DtcInfo lookupDtc(String code) {
  return dtcDatabase[code] ??
      DtcInfo(code, 'Unrecognized Code',
          'Fault code $code — check online DTC lookup for this code', 'medium');
}

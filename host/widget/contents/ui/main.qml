import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5
PlasmoidItem {
 id: root
 property bool details: false
 property bool hovered: false
 readonly property bool pinned: Plasmoid.configuration.visibilityMode === "always"
 readonly property bool revealed: pinned || hovered
 property var history: []
 Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
 property var stats: ({cpu:"—",amd:{temp:"—",load:"—"},nvidia:{temp:"—",load:"—"},fan:"",rpm:[null,null],ac:false})
 property var power: stats.power || ({active:false,requested:false,available:false})
 property bool busy: false
 property bool polling: false
 property string queuedAction: ""
 readonly property color selectedColor: "#3daee9"
 readonly property color optionColor: "#9da3ae"
 property string helper: "\"$HOME/.local/bin/razor14-thermal-status\""
 property string notice: ""
 preferredRepresentation: fullRepresentation
 function refresh() { if(!busy && !polling){polling=true; source.connectSource(helper);} }
 function action(mode) {
  if(busy)return;
  if(polling){queuedAction=mode;return;}
  busy=true;source.connectSource(helper+" "+mode);
 }
 function rpm(i) { return stats.rpm && stats.rpm[i] !== null ? stats.rpm[i] : "—"; }
 P5.DataSource {
  id: source; engine:"executable"; connectedSources:[]
  onNewData: function(name,data) {
   var output=data.stdout;
   disconnectSource(name);
   if(name===root.helper)root.polling=false; else root.busy=false;
   try {root.stats=JSON.parse(output); root.notice=root.stats.error || "";root.history=root.stats.history || [];}
   catch(e){root.notice="Status nicht verfügbar";}
   if(root.queuedAction!=="") {
    var nextAction=root.queuedAction;root.queuedAction="";
    root.action(nextAction);
   }
  }
 }
 Timer {interval:10000; running:true; repeat:true; onTriggered:root.refresh()}
 Component.onCompleted: refresh()
 fullRepresentation: Item {
  implicitWidth: 336; implicitHeight: 445
  Layout.minimumWidth: 336; Layout.minimumHeight: 445
 }
 PlasmaCore.Dialog {
  id: overlay
  title: "Razer 14 Monitor"
  type: PlasmaCore.Dialog.OnScreenDisplay
  location: PlasmaCore.Types.Floating
  outputOnly: false
  hideOnWindowDeactivate: false
  backgroundHints: PlasmaCore.Dialog.NoBackground
  visible: true
  x: Math.max(0, Screen.desktopAvailableWidth - width - 12); y: 12
  onClosing: function(close) { close.accepted = false; }
  mainItem: Item {
   width: 336; height: root.details && root.revealed ? 470 : 100
   HoverHandler { onHoveredChanged: root.hovered = hovered }
   Loader { anchors.fill: parent; sourceComponent: dashboard; opacity: root.revealed ? 1 : 0; enabled: root.revealed }

  }
 }

 Component {
 id: dashboard
 Item {
  Layout.minimumWidth: 330
  Layout.minimumHeight: 415
  implicitWidth:330
  implicitHeight:415
  ColumnLayout {
   anchors.right:parent.right
   anchors.rightMargin:root.revealed ? 8 : 0
   anchors.top:parent.top
   anchors.topMargin:root.revealed ? 6 : 0
   width:parent.width - (root.revealed ? 16 : 0)
   spacing:1
   ColumnLayout {
    visible: root.details
    Layout.alignment: Qt.AlignRight
    spacing: 0
    PC.RadioButton {
     text: "Mouseover: sichtbar"
     checked: !root.pinned
     onClicked: Plasmoid.configuration.visibilityMode = "hover"
    }
    PC.RadioButton {
     text: "Immer im Vordergrund"
     checked: root.pinned
     onClicked: Plasmoid.configuration.visibilityMode = "always"
    }
   }
   PC.Label {
    text: root.stats.nvidia.state || ""
    visible: root.stats.nvidia.source === "windows" && root.stats.nvidia.state !== "Windows"
    font.pointSize: 8; Layout.alignment: Qt.AlignRight
   }
   PC.Label {
    visible:!root.details && root.power.active
    text:"save";color:"#ffffff";Layout.alignment:Qt.AlignRight
    MouseArea {anchors.fill:parent;onClicked:root.details=true}
   }
   RowLayout {
    visible:root.details;Layout.alignment:Qt.AlignRight;spacing:0
    Repeater {
     model:["auto","save"]
     delegate:PC.Button {
      required property string modelData
      property bool selected:modelData==="auto" ? !root.power.requested : root.power.active
      text:modelData;implicitWidth:46;implicitHeight:26
      enabled:root.power.available && !root.busy && (modelData==="auto" || (!root.stats.ac && root.stats.nvidia.source !== "windows"))
      onClicked:root.action(modelData==="auto" ? "power-auto" : "power-save")
      contentItem:PC.Label {text:parent.text;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;color:parent.selected ? root.selectedColor : root.optionColor;font.bold:parent.selected}
      background:Rectangle {color:"transparent"}
     }
    }
   }
   Item {
    Layout.alignment:Qt.AlignRight
    Layout.preferredWidth: readouts.implicitWidth
    Layout.preferredHeight: readouts.implicitHeight
    GridLayout {
     id:readouts
     columns:root.details ? 2 : 1
     columnSpacing:10; rowSpacing:1
     PC.Label {text:root.stats.cpu; Layout.alignment:Qt.AlignRight}
     PC.Label {text:"CPU"; visible:root.details; Layout.alignment:Qt.AlignRight}
     PC.Label {text:root.stats.amd.temp + "  " + root.stats.amd.load; Layout.alignment:Qt.AlignRight}
     PC.Label {text:"Onboard"; visible:root.details; Layout.alignment:Qt.AlignRight}
     PC.Label {text:root.stats.nvidia.temp + "  " + root.stats.nvidia.load + (!root.details && root.stats.nvidia.source === "windows" ? " · Windows" : ""); Layout.alignment:Qt.AlignRight}
     PC.Label {text:root.stats.nvidia.source === "windows" ? "RTX · Windows" : "RTX 3070"; visible:root.details; Layout.alignment:Qt.AlignRight}
     PC.Label {text:root.rpm(0) + " | " + root.rpm(1); Layout.alignment:Qt.AlignRight}
     PC.Label {text:"Fan 1 | 2"; visible:root.details; Layout.alignment:Qt.AlignRight}
    }
    MouseArea {
     anchors.fill:parent
     cursorShape:Qt.PointingHandCursor
     acceptedButtons:Qt.LeftButton
     onClicked:root.details=!root.details
    }
   }
   RowLayout {
    visible:root.details
    Layout.alignment:Qt.AlignRight; spacing:4
    Repeater {
     model:["auto","max"]
     delegate: PC.Button {
      required property string modelData
      property bool selected: modelData==="auto" ? root.stats.fan==="Automatisch" : root.stats.fan==="5000 RPM"
      text:modelData
      implicitWidth:52; implicitHeight:26
      enabled:root.stats.ac && !root.busy
      onClicked:root.action(modelData)
      contentItem:PC.Label {text:parent.text; horizontalAlignment:Text.AlignHCenter; verticalAlignment:Text.AlignVCenter; color:parent.selected ? root.selectedColor : root.optionColor; font.bold:parent.selected}
      background:Rectangle {radius:4; color:"transparent"; border.width:0}
     }
    }
   }
   PC.Label {visible:root.details; text:"Last · 0–100 % · letzte 10 min"; font.pointSize:8; Layout.alignment:Qt.AlignRight}
   HistoryPlot {visible:root.details; points:root.history; mode:0; Layout.fillWidth:true; Layout.preferredHeight:78}
   RowLayout {
    visible:root.details; Layout.alignment:Qt.AlignRight; spacing:9
    PC.Label {text:"CPU";color:"#ffad4f";font.pointSize:8}
    PC.Label {text:"Onboard";color:"#6dcc86";font.pointSize:8}
    PC.Label {text:"RTX";color:"#3daee9";font.pointSize:8}
   }
   PC.Label {visible:root.details; text:"Temperatur 0–120 °C  |  Fan 0–6.000";font.pointSize:8;Layout.alignment:Qt.AlignRight}
   HistoryPlot {visible:root.details; points:root.history; mode:1; Layout.fillWidth:true; Layout.preferredHeight:90}
   RowLayout {
    visible:root.details;Layout.alignment:Qt.AlignRight;spacing:8
    PC.Label {text:"CPU";color:"#ffad4f";font.pointSize:8}
    PC.Label {text:"Onboard";color:"#6dcc86";font.pointSize:8}
    PC.Label {text:"RTX";color:"#3daee9";font.pointSize:8}
    PC.Label {text:"F1";color:"#cf8dff";font.pointSize:8}
    PC.Label {text:"F2";color:"#ffe066";font.pointSize:8}
   }
   PC.Label {text:root.notice; visible:root.details && text.length>0; Layout.alignment:Qt.AlignRight; font.pointSize:8; Layout.maximumWidth:parent.width;wrapMode:Text.Wrap}
  }
 }
}
}

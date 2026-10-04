import QtQuick
Canvas {
 id: chart
 property var points: []
 property int mode: 0
 onPointsChanged:requestPaint()
 onWidthChanged:requestPaint()
 onHeightChanged:requestPaint()
 onVisibleChanged:if(visible)requestPaint()
 onPaint: {
  var c=getContext("2d");c.clearRect(0,0,width,height);
  var l=25,r=mode===1?35:5,t=5,b=15,w=width-l-r,h=height-t-b;
  if(w<=0||h<=0)return;
  c.font="9px sans-serif";
  for(var j=0;j<3;j++){
   var y=t+h*j/2;c.strokeStyle="rgba(150,150,150,0.3)";c.lineWidth=1;c.beginPath();c.moveTo(l,y);c.lineTo(l+w,y);c.stroke();
   c.fillStyle="#999999";c.textAlign="right";c.fillText(String((mode===1?120:100)*(1-j/2)),l-3,y+3);
   if(mode===1){c.textAlign="left";c.fillText(String(6000-j*3000),l+w+3,y+3);}
  }
  c.fillStyle="#999999";c.textAlign="left";c.fillText("−10 min",l,height-2);c.textAlign="right";c.fillText("jetzt",l+w,height-2);
  if(!points.length)return;
  var end=points[points.length-1].t,start=end-600;
  var keys=mode===0?["cpu","amd","rtx"]:["ct","at","nt","f1","f2"];
  var colors=["#ffad4f","#6dcc86","#3daee9","#cf8dff","#ffe066"];
  for(var k=0;k<keys.length;k++){
   c.strokeStyle=colors[k];c.fillStyle=colors[k];c.lineWidth=k>2?1:1.5;
   if(mode===0){
    var bw=Math.max(0.6,w/60/3-0.2);
    for(var i=0;i<points.length;i++){
     var v=points[i][keys[k]];if(v===null||v===undefined)continue;
     var x=l+(points[i].t-start)/600*w-(3-k)*bw;
     var bh=Math.min(100,Math.max(0,v))/100*h;c.fillRect(x,t+h-bh,bw,bh);
    }
   }else{
    var pen=false,last=0;c.beginPath();
    for(var i=0;i<points.length;i++){
     var v=points[i][keys[k]];if(v===null||v===undefined){pen=false;continue;}
     var x=l+(points[i].t-start)/600*w,y=t+h-Math.max(0,Math.min(1,v/(k>2?6000:120)))*h;
     if(!pen||points[i].t-last>20)c.moveTo(x,y);else c.lineTo(x,y);
     pen=true;last=points[i].t;
    }c.stroke();
   }
  }
 }
}

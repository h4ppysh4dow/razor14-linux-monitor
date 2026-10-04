use razer_laptop::{razer_devices,razer_hidapi::RazerPacket};
fn main() {
 for d in razer_devices().unwrap().into_iter().filter(|d|d.product_id==0x0270) {
 let mut dev=d.open().unwrap();
 for zone in [1u8,2u8] {
 let mut p=RazerPacket::new(0x0d,0x88,4);p.args[0]=0;p.args[1]=zone;
 match dev.send_report(p) {Some(r)=>println!("zone={} status={} args={:?}",zone,r.status,&r.args[..8]),None=>println!("zone={} unsupported or failed",zone)}
 }
 }
}

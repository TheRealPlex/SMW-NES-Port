"""Headless standard libretro frontend. Uses an existing SNES emulator core."""
import ctypes as C
from pathlib import Path
class GameInfo(C.Structure):
 _fields_=[('path',C.c_char_p),('data',C.c_void_p),('size',C.c_size_t),('meta',C.c_char_p)]
class Snes:
 def __init__(self,core,rom):
  self.lib=C.CDLL(str(Path(core).resolve()));self.keys=0;self.frame=0;self.video=None;self.pixel=0
  env_t=C.CFUNCTYPE(C.c_bool,C.c_uint,C.c_void_p)
  vid_t=C.CFUNCTYPE(None,C.c_void_p,C.c_uint,C.c_uint,C.c_size_t)
  aud_t=C.CFUNCTYPE(None,C.c_int16,C.c_int16)
  batch_t=C.CFUNCTYPE(C.c_size_t,C.c_void_p,C.c_size_t)
  poll_t=C.CFUNCTYPE(None)
  inp_t=C.CFUNCTYPE(C.c_int16,C.c_uint,C.c_uint,C.c_uint,C.c_uint)
  def env(cmd,data):
   if cmd==3:C.cast(data,C.POINTER(C.c_bool))[0]=True;return True
   if cmd==10:self.pixel=C.cast(data,C.POINTER(C.c_int))[0];return self.pixel in (0,1,2)
   if cmd==17:C.cast(data,C.POINTER(C.c_bool))[0]=False;return True
   if cmd in (11,16,18,35):return True
   return False
  def video(ptr,w,h,pitch):
   if ptr:self.video=(C.string_at(ptr,h*pitch),w,h,pitch)
  def state(port,device,index,button):
   if port!=0:return 0
   if button==256:return C.c_int16(self.keys).value
   return int(bool(self.keys&(1<<button)))
  self.callbacks=[env_t(env),vid_t(video),aud_t(lambda l,r:None),batch_t(lambda ptr,n:n),poll_t(lambda:None),inp_t(state)]
  for n,cb in zip(['environment','video_refresh','audio_sample','audio_sample_batch','input_poll','input_state'],self.callbacks):
   fun=getattr(self.lib,'retro_set_'+n);fun.argtypes=[type(cb)];fun(cb)
  self.lib.retro_init()
  self.lib.retro_load_game.argtypes=[C.POINTER(GameInfo)];self.lib.retro_load_game.restype=C.c_bool
  self.rom=C.create_string_buffer(Path(rom).read_bytes())
  info=GameInfo(str(Path(rom).resolve()).encode(),C.cast(self.rom,C.c_void_p),len(self.rom)-1,None)
  assert self.lib.retro_load_game(C.byref(info))
  self.lib.retro_set_controller_port_device(0,1)
  self.lib.retro_get_memory_size.argtypes=[C.c_uint];self.lib.retro_get_memory_size.restype=C.c_size_t
  self.lib.retro_get_memory_data.argtypes=[C.c_uint];self.lib.retro_get_memory_data.restype=C.c_void_p
  size=self.lib.retro_get_memory_size(2);assert size>=131072,size
  self.ram=(C.c_ubyte*size).from_address(self.lib.retro_get_memory_data(2))
 def run(self,n=1,keys=0):
  self.keys=keys
  for _ in range(n):self.lib.retro_run();self.frame+=1
 def word(self,a):return self.ram[a]+256*self.ram[a+1]
 def byte(self,a):return self.ram[a]
 def state(self):
  return {'frame':self.frame,'mode':self.byte(0x100),'x':self.word(0x94),'y':self.word(0x96),'vx':C.c_int8(self.byte(0x7b)).value,'vy':C.c_int8(self.byte(0x7d)).value,'air':self.byte(0x72)}
 def save(self):
  self.lib.retro_serialize_size.restype=C.c_size_t;n=self.lib.retro_serialize_size();buf=C.create_string_buffer(n)
  self.lib.retro_serialize.argtypes=[C.c_void_p,C.c_size_t];self.lib.retro_serialize.restype=C.c_bool
  assert self.lib.retro_serialize(buf,n);return buf.raw
 def load(self,b):
  buf=C.create_string_buffer(b);self.lib.retro_unserialize.argtypes=[C.c_void_p,C.c_size_t];self.lib.retro_unserialize.restype=C.c_bool
  assert self.lib.retro_unserialize(buf,len(b))

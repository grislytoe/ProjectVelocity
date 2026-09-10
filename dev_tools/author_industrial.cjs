// Offline authoring source: emits ordinary inspectable M13 section scenes, never runtime geometry.
const fs = require('fs');
const root = require('path').resolve(__dirname, '..');
function write(path, text) { fs.mkdirSync(require('path').dirname(root+'/'+path),{recursive:true}); fs.writeFileSync(root+'/'+path,text+'\n'); }
const W=5200;
class Section {
 constructor(id) { this.id=id; this.ext=[]; this.sub=[]; this.nodes=['[node name="Section" type="Node2D"]']; this.major=[]; this.n=0;
  this.marker('Entrance',0,600); this.marker('Exit',W,600); this.marker('Start',120,566);
  this.marker('Checkpoint',180,388); this.marker('Respawn',180,566); this.marker('Finish',W-160,100);
 }
 marker(name,x,y){this.nodes.push(`[node name="${name}" type="Marker2D" parent="."]\nposition = Vector2(${x}, ${y})`);}
 rect(name,x,y,w,h,color='0.27, 0.31, 0.34, 1',solid=true){
  if(solid){this.sub.push(`[sub_resource type="RectangleShape2D" id="${name}"]\nsize = Vector2(${w}, ${h})`);
   this.nodes.push(`[node name="${name}" type="StaticBody2D" parent="."]\nposition = Vector2(${x+w/2}, ${y+h/2})\n[node name="Collision" type="CollisionShape2D" parent="${name}"]\nshape = SubResource("${name}")`);
   this.major.push(`NodePath("${name}/Collision")`);
   this.nodes.push(`[node name="Visual" type="Polygon2D" parent="${name}"]\npolygon = PackedVector2Array(${-w/2}, ${-h/2}, ${w/2}, ${-h/2}, ${w/2}, ${h/2}, ${-w/2}, ${h/2})\ncolor = Color(${color})`);
   this.rect(name+'Edge',x,y,w,5,'0.50, 0.76, 0.76, 1',false);
  } else this.nodes.push(`[node name="${name}" type="Polygon2D" parent="."]\npolygon = PackedVector2Array(${x}, ${y}, ${x+w}, ${y}, ${x+w}, ${y+h}, ${x}, ${y+h})\ncolor = Color(${color})`);
 }
 floor(a,b,y=600){this.rect('Floor'+this.n++,a,y,b-a,100);}
 object(name,module,x,y,config=null){const id='e'+this.n++; this.ext.push(`[ext_resource type="PackedScene" path="res://gameplay/${module}.tscn" id="${id}"]`);
  let conf=''; if(config){const cid='c'+this.n++, sid='s'+this.n++;this.ext.push(`[ext_resource type="Script" path="res://gameplay/${config[0]}.gd" id="${sid}"]`);this.sub.push(`[sub_resource type="Resource" id="${cid}"]\nscript = ExtResource("${sid}")\n${config[1]}`); conf=`\nconfig = SubResource("${cid}")`;}
  this.nodes.push(`[node name="${name}" parent="." instance=ExtResource("${id}")]\nposition = Vector2(${x}, ${y})${conf}`);
 }
 spikes(x,w=100,mode=0){this.object('Spikes'+this.n,'hazards/spikes',x,588,['hazards/spike_config',`size = Vector2(${w}, 24)\nmode = ${mode}${mode===2?'\ntrigger_on_player_overlap = true':''}`]);}
 saw(x,y,moving=false){if(!moving)this.object('Saw'+this.n,'hazards/saw',x,y);else {
  const sid='routeScript'+this.n, rid='route'+this.n;this.ext.push(`[ext_resource type="Script" path="res://gameplay/platforms/moving_platform_config.gd" id="${sid}"]`);
  this.sub.push(`[sub_resource type="Resource" id="${rid}"]\nscript = ExtResource("${sid}")\nroute = PackedVector2Array(0, 0, 0, -140)\nspeed = 160.0\nwaits = PackedFloat32Array(0.5, 0.5)`);
  this.object('MovingSaw','hazards/saw',x,y,['hazards/saw_config',`moving = true\npath = SubResource("${rid}")`]);}}
 laser(x,y,w,h,mode=0){this.object('Laser'+this.n,'hazards/laser',x,y,['hazards/laser_config',`mode = ${mode}\nsize = Vector2(${w}, ${h})`]);}
 sign(x,y,key){this.nodes.push(`[node name="Sign${this.n++}" type="Label" parent="."]\noffset_left = ${x}.0\noffset_top = ${y}.0\noffset_right = ${x+750}.0\noffset_bottom = ${y+60}.0\ntheme_override_colors/font_color = Color(0.63, 0.85, 0.83, 1)\ntheme_override_font_sizes/font_size = 28\ntext = "${key}"`);}
 save(){
  // Broad concrete silhouettes and recesses at distinct depths; all are ordinary polygons.
  const bg=[];for(let x=0;x<W;x+=520)bg.push(`[node name="Mass${x}" type="Polygon2D" parent="."]\nz_index = -10\npolygon = PackedVector2Array(${x}, -420, ${x+360}, -420, ${x+360}, 940, ${x}, 940)\ncolor = Color(0.065, 0.087, 0.105, 1)`);
  this.nodes.splice(1,0,...bg);this.sign(60,220,'IND_SECTION_'+this.id);
  const accents=['0.23, 0.48, 0.53, 1','0.32, 0.43, 0.53, 1','0.50, 0.39, 0.23, 1','0.26, 0.45, 0.43, 1','0.51, 0.40, 0.21, 1','0.47, 0.31, 0.25, 1','0.42, 0.30, 0.37, 1','0.32, 0.47, 0.40, 1'];
  // Recessed structural ribs, overhead service pipes, concrete joints and anchor bolts.
  for(let x=0;x<W;x+=520){
   this.nodes.push(`[node name="Rib${x}" type="Polygon2D" parent="."]\nz_index = -8\npolygon = PackedVector2Array(${x+32}, -360, ${x+64}, -360, ${x+64}, 940, ${x+32}, 940)\ncolor = Color(0.11, 0.14, 0.17, 1)`);
   this.nodes.push(`[node name="Crossmember${x}" type="Polygon2D" parent="."]\nz_index = -7\npolygon = PackedVector2Array(${x}, 40, ${x+520}, 40, ${x+520}, 70, ${x}, 70)\ncolor = Color(${accents[this.id-1]})`);
   this.rect('Pipe'+x,x,96,480,7,'0.18, 0.23, 0.27, 1',false);
   this.rect('Coupler'+x,x+460,86,14,28,'0.26, 0.32, 0.36, 1',false);
  }
  const floors=this.major.slice();
  for(const path of floors){const name=path.match(/\("([^/]+)/)[1];
   const parent=this.nodes.find(v=>v.startsWith(`[node name="${name}" type="StaticBody2D"`));
   const size=this.sub.find(v=>v.startsWith(`[sub_resource type="RectangleShape2D" id="${name}"`)).match(/Vector2\(([^,]+), ([^)]+)\)/);
   const w=Number(size[1]),h=Number(size[2]);
   for(let x=-w/2+160;x<w/2;x+=240){this.nodes.push(`[node name="Joint${this.n++}" type="Line2D" parent="${name}"]\npoints = PackedVector2Array(${x}, ${-h/2+8}, ${x}, ${h/2-5})\nwidth = 2.0\ndefault_color = Color(0.17, 0.21, 0.24, 1)`);}
   for(const x of [-w/2+12,w/2-12])this.nodes.push(`[node name="Bolt${this.n++}" type="Polygon2D" parent="${name}"]\npolygon = PackedVector2Array(${x-3}, ${-h/2+14}, ${x+3}, ${-h/2+14}, ${x+3}, ${-h/2+20}, ${x-3}, ${-h/2+20})\ncolor = Color(0.58, 0.61, 0.61, 1)`);
  }
  for(let x=700;x<W;x+=1000){this.rect('Route'+x,x,720,240,10,'0.12, 0.40, 0.42, 1',false);}
  write(`map_data/industrial/section_${this.id}.tscn`,['[gd_scene format=3]',...this.ext,...this.sub,...this.nodes].join('\n\n'));
  write(`map_data/industrial/section_${this.id}.tres`,`[gd_resource type="Resource" script_class="MapSectionDefinition" format=3]\n[ext_resource type="Script" path="res://map_data/map_section_definition.gd" id="s"]\n[resource]\nscript = ExtResource("s")\nsection_id = &"industrial_${this.id}"\nscene_path = "res://map_data/industrial/section_${this.id}.tscn"\nmajor_geometry = Array[NodePath]([${this.major.join(', ')}])`);
 }
}
let s=new Section(1);s.floor(0,4200);s.floor(4520,W);s.rect('Crate',1000,520,160,80);s.spikes(2000);s.rect('Duct',2860,380,500,80);s.spikes(3060,80);s.sign(2760,260,'IND_LOW_JUMP');s.sign(3970,350,'IND_GAP');s.save();
s=new Section(2);s.floor(0,1200);s.floor(1200,2200,720);s.floor(3000,W);s.rect('Step',1840,600,240,120);
s.object('OneWay','platforms/one_way_platform',2220,480,['platforms/platform_config','one_way = true\npolygon = PackedVector2Array(-240, 0, 240, 0, 240, 24, -240, 24)']);s.rect('Upper',2580,360,300,80);s.object('Bridge','platforms/breakable_platform',2890,480);s.sign(1340,350,'IND_ONE_WAY');
s.spikes(3900,160);s.saw(4550,570);s.save();
s=new Section(3);s.floor(0,W);s.spikes(1100,120);s.rect('ExpressPerch',1900,340,240,40,'0.48, 0.38, 0.20, 1');s.rect('ShaftWall',2500,180,300,420);s.rect('Landing',2800,280,500,80);s.rect('StepDown',3440,420,400,80);s.sign(1870,250,'IND_WALL');s.sign(1870,200,'IND_SHORTCUT');s.spikes(4270,180);s.save();
s=new Section(4);s.floor(0,2360);s.floor(3280,W);s.spikes(1100,120);s.sign(1780,260,'IND_DASH');s.rect('GapBottom',2360,960,920,80,'0.12, 0.16, 0.18, 1',false);s.saw(4210,565);s.spikes(4800,100,1);s.save();
s=new Section(5);s.floor(0,2000);s.floor(3200,W);s.object('Shuttle','platforms/moving_platform',2430,580,['platforms/moving_platform_config','polygon = PackedVector2Array(-240, 0, 240, 0, 240, 24, -240, 24)\nroute = PackedVector2Array(0, 0, 340, 0)']);s.sign(1430,310,'IND_MOVING');s.saw(4050,570,true);s.spikes(4640,120);s.save();
s=new Section(6);s.floor(0,1680);s.floor(3700,W);s.object('Launch','platforms/jump_pad',1810,600);s.rect('HighDeck',2080,140,840,80);s.rect('Descent',3120,340,300,80);s.laser(2420,100,180,18);s.sign(1300,330,'IND_PAD');s.spikes(4340,160);s.save();
s=new Section(7);s.floor(0,W);s.spikes(1050,100,2);s.laser(2200,540,18,120,1);s.rect('Cover',3000,500,160,100);s.object('Turret','hazards/turret',3880,390);s.spikes(4540,100);s.sign(1710,270,'IND_LASER');s.sign(2830,240,'IND_COVER');s.save();
s=new Section(8);s.floor(0,2100);s.floor(2580,W);s.saw(1000,566);s.object('Temporary','platforms/breakable_platform',2340,600);s.spikes(3300,140);s.laser(4070,540,18,120,1);s.sign(560,280,'IND_FINAL');s.save();
let ext=['map_definition','map_section_placement','map_point'].map((x,i)=>`[ext_resource type="Script" path="res://map_data/${x}.gd" id="${['map','p','point'][i]}"]`);
ext.push('[ext_resource type="Texture2D" path="res://map_data/industrial_preview.svg" id="preview"]');
ext.push('[ext_resource type="Resource" path="res://map_data/industrial_camera.tres" id="camera"]');
let sub=[];for(let i=1;i<=8;i++){ext.push(`[ext_resource type="Resource" path="res://map_data/industrial/section_${i}.tres" id="s${i}"]`);sub.push(`[sub_resource type="Resource" id="p${i}"]\nscript = ExtResource("p")\ninstance_id = &"s${i}"\nsection = ExtResource("s${i}")\ntransform = Transform2D(1, 0, 0, 1, ${(i-1)*W}, 0)${i<8?`\nnext_id = &"s${i+1}"`:''}`);}
function point(id,sec,anchor,respawn=''){sub.push(`[sub_resource type="Resource" id="${id}"]\nscript = ExtResource("point")\npoint_id = &"${id}"\nsection_id = &"s${sec}"\nanchor = NodePath("${anchor}")${respawn?`\nrespawn_anchor = NodePath("${respawn}")`:''}\ntrigger_size = Vector2(70, ${id.startsWith('cp') ? 450 : 1000})`);}
point('start',1,'Start','Start');for(let i=2;i<=8;i++)point('cp'+(i-1),i,'Checkpoint','Respawn');point('finish',8,'Finish');
write('map_data/industrial_foundry.tres',['[gd_resource type="Resource" script_class="MapDefinition" format=3]',...ext,...sub,`[resource]\nscript = ExtResource("map")\nmap_id = "industrial_foundry"\nmap_version = 2\nname_key = "IND_MAP"\ndescription_key = "IND_DESCRIPTION"\npreview = ExtResource("preview")\nmap_type = "official"\ncamera_bounds = ExtResource("camera")\nexpected_duration_seconds = 90\npar_time_ticks = 5400\ndeath_bounds = Rect2(-6000, 1100, 53600, 10000)\nsections = Array[ExtResource("p")]([${Array.from({length:8},(_,i)=>`SubResource("p${i+1}")`).join(', ')}])\nstart = SubResource("start")\nfinish = SubResource("finish")\ncheckpoints = Array[ExtResource("point")]([${Array.from({length:7},(_,i)=>`SubResource("cp${i+1}")`).join(', ')}])\ndeclared_checksum = ""`].join('\n\n'));
write('map_data/industrial_preview.svg',`<svg xmlns="http://www.w3.org/2000/svg" width="800" height="260" viewBox="0 0 800 260"><rect width="800" height="260" fill="#101923"/><path d="M40 230V90h110v140m30 0V30h90v200m30 0V120h120v110m40 0V70h140v160m30 0V25h95v205" fill="#293b46" stroke="#40535d" stroke-width="4"/><path d="M0 210h160l60-75h90l65 55h90l60-100h90l75 120h110" fill="none" stroke="#65d6ca" stroke-width="7"/><path d="M367 225l10-22 10 22m6 0 10-22 10 22" fill="#ef5366"/><circle cx="540" cy="75" r="17" fill="#ffb947"/></svg>`);

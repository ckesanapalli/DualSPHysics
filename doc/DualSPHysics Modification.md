# Modification in the DualSPHysics code

## CPU Modification (JSPHCpu.cpp)

### Original function in CPU based DualSPHysics code:

````c++
//==============================================================================
/// Applies a matrix movement to a group of particles.
/// Aplica un movimiento matricial a un conjunto de particulas.
//==============================================================================
void JSphCpu::MoveMatBound(unsigned np, // Number of Particles in the given group
                           unsigned ini, // Identifier of initial particle
                           // ===========================================
                           // ======= Calculated from the Step 3 ========
                           tmatrix4d m, // Position displacement matrix
                           // ===========================================
                           double dt, // timestep length
                           const unsigned *ridpmv,  // Pointer of particle Identifiers
                           tdouble3 *pos, // Particle Position pointer 
                           unsigned *dcell, // Pointer of Cell of Particles
                           tfloat4 *velrhop, // Velocity pointer
                           typecode *code // Indicator of group of particles
                          )const
{
  
    // Final particle position
    const unsigned fin=ini+np;
    // for loop for all particles in the group
  	for(unsigned id=ini;id<fin;id++){
    // Particle Position according to id
	const unsigned pid=RidpMove[id];
        // UINT_MAX = maximum unsigned int value
        // if particle ID is not exceeding the UINT_MAX
        if(pid!=UINT_MAX){
            // Position of the Particle (x, y, z)
            tdouble3 ps=pos[pid];
            // New Position of the Particle (x, y, z)
            tdouble3 ps2=MatrixMulPoint(m,ps);
            // If the model is 2-D, then no position change in y-axis
            if(Simulate2D)ps2.y=ps.y;
            // displacment
            const double dx=ps2.x-ps.x, dy=ps2.y-ps.y, dz=ps2.z-ps.z;
            // Updating the position using the displacement
            UpdatePos(ps,dx,dy,dz,false,pid,pos,dcell,code);
            // Updating the velocity
            velrhop[pid].x=float(dx/dt);  
            velrhop[pid].y=float(dy/dt);  
            velrhop[pid].z=float(dz/dt);
    }
  }
}
````

### Modified function in CPU based DualSPHysics code:

````c++
//==============================================================================
/// Applies a matrix movement to a group of particles.
/// Aplica un movimiento matricial a un conjunto de particulas.
//==============================================================================
void JSphCpu::MoveMatBound(unsigned np, // Number of Particles in the given group
                           unsigned ini, // Identifier of particle
                           // ===========================================
                           // ======= Modification  =====================
                           double timestep, // Position transformation matrix
                           // ===========================================
                           double dt, // timestep length
                           const unsigned *ridpmv,  // Pointer of particle Identifiers
                           tdouble3 *pos, // Particle Position pointer 
                           unsigned *dcell, // Pointer of Cell of Particles
                           tfloat4 *velrhop, // Velocity pointer
                           typecode *code // Indicator of group of particles
                          )const
{
  
    // Final particle position
    const unsigned fin=ini+np;
    // ======= Modification  =====================
    // Wave Parameters
    const double omega = TWOPI * 0.3; // angular frequency of the piston
	const double depth = 0.3; // depth of the water in the tank
    const double waveamp = 0.12; // Amplitude 
    
    // Calculation of the wave number
    double temp = 1;
    double wave_number = 0.1; // Wave number of the wave
    while (abs(wave_number - temp) > 1e-5) {
        temp = wave_number;
        wave_number = omega*omega / (-Gravity.z* tanh(wave_number * depth));
    }
	// ===========================================
    // for loop for all particles in the group
  	for(unsigned id=ini;id<fin;id++){
    // Particle Position according to id
	const unsigned pid=RidpMove[id];
        
        // UINT_MAX = maximum unsigned int value
        // if particle ID is not exceeding the UINT_MAX
        if(pid!=UINT_MAX){
            
            // Position of the Particle (x, y, z)
            tdouble3 ps=pos[pid];
            
            // ======= Modification  =====================
            // New Velocity 
            tdouble3 waveveln_h = TDouble3(0);
			waveveln_h.x = pistonamp* omega* exp(wave_number * ps.z)* cos(omega* (timestep));
            // If the model is 2-D, then velocity in y-axis is zero
			if(Simulate2D)waveveln_h.y=0.0;
            
            // displacment
			const double dx = waveveln_h.x * dt;
            const double dy = waveveln_h.y * dt; 
            const double dz = waveveln_h.z * dt;
			
            // Updating the position using the displacement
			UpdatePos(ps, dx, dy, dz, false, pid, pos, dcell, code);
            
            // Updating the velocity
			velrhop[pid].x = float(waveveln_h.x);  
            velrhop[pid].y = float(waveveln_h.y);  
            velrhop[pid].z = float(waveveln_h.z);
			// ===========================================
    }
  }
}
````

## GPU Modification (JSPHCpu.cpp)

### Original function in GPU based DualSPHysics code:

````c++
template<bool periactive,bool simulate2d> 
__global__ void KerMoveMatBound(unsigned n, // Number of Particles in the given group
                               unsigned ini,// Identifier of initial particle
                               // ===========================================
                               // ======= Calculated from the Step 3 ========
                               tmatrix4d m, // Position displacement matrix
                               // ===========================================
                               double dt, // timestep length
                               const unsigned *ridpmv, // Pointer of particle Identifiers
                               double2 *posxy, // Particle Position (x, y) pointer 
                               double *posz, // Particle Position (z) pointer 
                               unsigned *dcell, // Pointer of Cell of Particles
                               float4 *velrhop, // Velocity pointer
                               typecode *code // Indicator of group of particles
                               )
{
  // handle the data at this index
  unsigned p=blockIdx.y*gridDim.x*blockDim.x + blockIdx.x*blockDim.x + threadIdx.x; 
  
  if(p<n){
  // particle Index.
    int pid=ridpmv[p+ini];
    
    if(pid>=0){
    // Particle Position according to id
      double2 rxy=posxy[pid];
      double3 rpos=make_double3(rxy.x,rxy.y,posz[pid]);
      
      //-Computes new position.
      double3 rpos2;
      rpos2.x= rpos.x*m.a11 + rpos.y*m.a12 + rpos.z*m.a13 + m.a14;
      rpos2.y= rpos.x*m.a21 + rpos.y*m.a22 + rpos.z*m.a23 + m.a24;
      rpos2.z= rpos.x*m.a31 + rpos.y*m.a32 + rpos.z*m.a33 + m.a34;
      
      // If the model is 2-D, then no position change in y-axis
      if(simulate2d)rpos2.y=rpos.y;
      //-Computes displacement and updates position.
      const double dx=rpos2.x-rpos.x;
      const double dy=rpos2.y-rpos.y;
      const double dz=rpos2.z-rpos.z;
      
      // Updating the position using the displacement
      KerUpdatePos<periactive>(make_double2(rpos.x,rpos.y),rpos.z,dx,dy,dz,false,pid,posxy,posz,dcell,code);
      
      // Updating the velocity
      velrhop[pid]=make_float4(float(dx/dt),float(dy/dt),float(dz/dt),velrhop[pid].w);
    }
  }
}
````

### Modified function in GPU based DualSPHysics code:

````c++
template<bool periactive,bool simulate2d> 
__global__ void KerMoveMatBound(unsigned n, // Number of Particles in the given group
                               unsigned ini,// Identifier of initial particle
                               // ===========================================
                               // ======= Calculated from the Step 3 ========
                               tmatrix4d m, // Position displacement matrix
                               // ===========================================
                               double dt, // timestep length
                               const unsigned *ridpmv, // Pointer of particle Identifiers
                               double2 *posxy, // Particle Position (x, y) pointer 
                               double *posz, // Particle Position (z) pointer 
                               unsigned *dcell, // Pointer of Cell of Particles
                               float4 *velrhop, // Velocity pointer
                               typecode *code // Indicator of group of particles
                               )
{
  // handle the data at this index
  unsigned p=blockIdx.y*gridDim.x*blockDim.x + blockIdx.x*blockDim.x + threadIdx.x; 
  
  if(p<n){
  	// particle Index.
    int pid=ridpmv[p+ini];
    
    if(pid>=0){
    	// Particle Position according to id
      	double2 rxy=posxy[pid];
      	double3 rpos=make_double3(rxy.x,rxy.y,posz[pid]);
      
		// ============================ Modification ============================
		double omega = TWOPI * 0.5; // angular frequency of the piston
		double wave_number = 1.0; // wave_number in the tank
		double Amplitude = 0.25; // Wave Amplitude
		
		// New velocity 
		double3 wavevel;
		wavevel.x = Amplitude * omega * exp(wave_number* rpos.z)* cos(omega* timestep);
		wavevel.y = 0.0;
		wavevel.z = 0.0;

		//-Computes displacement
		const double dx = wavevel.x * dt;
		const double dy = wavevel.y * dt;
		const double dz = wavevel.z * dt;

        // If the model is 2-D, then velocity in y-axis is zero
		if (simulate2d)wavevel.y = 0.0;
		
		// Updating the Position
		KerUpdatePos<periactive>(make_double2(rpos.x, rpos.y), rpos.z, dx, dy, dz, false, pid, posxy, posz, dcell, code);

		//-Computing new velocity.
		velrhop[pid] = make_float4(float(wavevel.x), float(wavevel.y), float(wavevel.z), velrhop[pid].w);

			// ============================ Main change ============================
		}
	}
}
````














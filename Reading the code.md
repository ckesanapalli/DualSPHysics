# Reading the Source for adding a Varying Boundary Motion to the source code

## Desired Input

The input motion must be a function of x, z, t. That means it should be a 3x3 matrix input.

## Simplified Desired Input

The input is a the exponentially decreasing sinusoidal motion 
$$
x = A e^{kz} sin(wt)
$$

Therefore the inputs for the desired function are the $(x, z, t)$ of the selected boundary. i.e.,

```c++
void JMotionMov::VaryRectFile(double x, double z, double t){
    
}
```

DualSPHysics team responded saying that the functions that needs to be edited are `ComputeStep` and `ComputeSymplectic` where the functions that are in the file 

Before all this first we need to find the file that deal with the boundary particle motion. That is the functions that calculates and updates the boundary particle position.

The 
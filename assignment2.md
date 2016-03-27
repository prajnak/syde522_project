# SYDE 522 Assignment 2
## Autoencoding Histo-pathology images
The images were downloaded from learn and loaded into MATLAB. They were then converted into 32x32 grayscale images. Since all these operations were done in MATLAB 2015a, which did not have a default implementation of the autoencoder class, a feedforwardnet was created and configured with a single hidden layer of varying sizes starting at 1024/2, where 1024 = 32x32.
### Autoencoder with hidden layer size = 1024/2
The performance(MSE) of this autoencoder is shown in the plot below:
[]![MSE peformance for hidden layer size = 512](hl_512_mse.png)
[]![MSE peformance for hidden layer size = 512](hl_512_error.png) 	hl_512_error.png

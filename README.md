
<h1 align="center">CATNIP</h1>

 <p align="center">
CATNIP is whole brain <b>C</b>ellular <b>A</b>c<b>T</b>ivity estimation : a <b>N</b>ice <b>I</b>mage processing <b>P</b>rogram 
<br /> 
<p>
</div>



<a name="readme-top"></a>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>      
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
   <li><a href="#gui">GUI</a></li>
   <li><a href="#windows-gui">Windows GUI in WSL</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
   <li><a href="#publications">Publications</a></li>
    <li><a href="#references">References</a></li>
  </ol>
</details>





<!-- ABOUT THE PROJECT -->
## About The Project

CATNIP is designed to analyze cleared mouse brain images scanned in Lightsheet microscopes, e.g. iDISCO, CLARITY, and SHIELD
type images. It can process very large (Terabyte scale) images. It was built for analysis of nuclear
immunolabeling but can likely be adapted to other labels. It was inspired by the ClearMap pipeline [[1]](#1)[[2]](#2).

There are three main steps of the pipeline,

1. Registration: The images are downsampled to approximately 25micron voxel size. They are corrected
for any intensity inhomogeneity using N4 [[3]](#3). The inhomogeneity corrected and downsampled
image is then registered to the Allen Brain Atlas (ABA) [[4]](#4) via antsRegistration [[5]](#5).

2. Segmentation : Since the labeled cells are generally of spherical shape on cleared images,
they are segmented on the original image space using a fast radial symmetry transform
(FRST) [[6]](#6). The transform provides a continuous valued "membership" type image, which
can thresholded as various values to generate binary cell segmentation images.

3. Statistics and heatmaps: Cells in 3D are counted for each of the structural labels given by
the ABA. Heatmaps of the cell counts are also generated for visualization and statistics.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<p align="center">
  <img src="https://github.com/snehashis-roy/CATNIP/blob/master/img/movie2.gif" alt="animated" height="400"/>  
</p>

<!-- GETTING STARTED -->
## Getting Started

CATNIP is currently configured to run on a 64-bit Linux workstation or cluster. It can also
be run on any Windows workstation via a virtualization software, e.g. VMWare. We have tested CATNIP on Red Hat 
Enterprise Linux 8.x and Rocky Linux 9. See  <a href="#windows-gui">Windows WSL</a> section
to install in Windows via WSL.


CATNIP is primarily written in MATLAB, while parts (e.g., registration) of the pipeline are
run via ANTs [[5]](#5) toolbox. Note that it is *not* required to have an active MATLAB license as all
codes are compiled. The pipeline is optimized to use minimum amount of memory at the cost of
repeated read/write operations from disk. Minimum requirement to run the pipeline is a 8-core
CPU, 32GB RAM, and a reasonably fast drive. A recommended requirement is 12-core CPU,
64GB RAM, and a fast SSD. With Terabyte scale images, 128GB RAM and an SSD with at least
twice the size of the image are recommended to store temporary files. Administrator access is not
required and not recommended for any of the installation process.

Detailed installation instructions are given in the [documentation](CATNIP_Documentation.pdf).

### Prerequisites

* Matlab Compiler Runtime (MCR) 

Download the 64-bit Linux MCR installer for MATLAB 2022a (v912)
```
https://www.mathworks.com/products/compiler/matlab-runtime.html
```

* ANTs

Either download the binaries for the corresponding OS, or build from source
```
https://github.com/ANTsX/ANTs/releases
```
We have extensively tested the pipeline with ANTs version 2.2.0. Note that with
newer versions of ANTs, it is possible that some command line arguments
we used may be deprecated.


### Installation

1. Install the MCR (v912) to somewhere suitable.

2. Add the MCR installation path, i.e. the v912 directory, to all of the included shell scripts' MCRROOT variable. 
In each of the 16 shell scripts, replace the line containing ```MCRROOT=/usr/local/matlab-compiler/v912```
to the path where the MCR is installed, e.g.,
```
MCRROOT=/home/user/MCR/v912
```
if the MCR is installed in ```/home/user/MCR```.

3. Install ANTs binaries and add the binary path to shell \$PATH
```
export PATH=/home/user/ANTs-2.2.0/install/bin:${PATH}
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

The input image should follow a few requirements,
1. the input image must be within a folder in 2D slices,
2. the input image must be either one single hemisphere plus a few slices of the other hemisphere in sagittal
   orientation or whole brain in axial/horizontal orientation. 
4. the depth (z-axis) must be toward the midline for single hemisphere sagittal orientation or cerebellum to
   brainstem for whole brain horizontal orientation.

Please see the [documentation](CATNIP_Documentation.pdf) section 4 for details about the correct choice
of atlas. Please also check [documentation](CATNIP_Documentation.pdf) section 5 about the 
correct orientation of the input image or an [example image](example_data.txt).

The main script is ```CATNIP.sh```. An example usage is,
```
./CATNIP.sh --cfos /home/user/example_data/ --o /home/user/output/ --ob no --lrflip yes --udflip yes \
--thr 1000:1000:5000 --dsfactor 6x6x5 --cellradii 2,3,4 --ncpu 16 --atlasversion v2 --cellsizepx 9,900
```

If the images have some artifacts coming from shadows, bubbles, or tearing, it is possible to add an
exclusion mask. The mask is solely used to exclude cell counts from the labels that overlap with the mask.
An example command in that scenario is the following,
```
./CATNIP.sh --cfos /home/user/example_data/ --o /home/user/output/ --ob no --lrflip yes --udflip yes \
--thr 1000:1000:5000 --dsfactor 6x6x5 --cellradii 2,3,4 --ncpu 16 --atlasversion v2 \
--exclude_mask example_data_artifact_mask.tif --mask_ovl_ratio 0.33  --cellsizepx 9,900
```

For details of each of the arguments, please refer to the [documentation](CATNIP_documentation.pdf) section 6.
These default parameters are primarily applicable to 3.7x3.7x5um images. For images with different pixel sizes, the parameters
may need to be changed, e.g., see Fig 4 of the [documentation](CATNIP_documentation.pdf).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GUI -->
## GUI
A simple GUI based on Tkinter is provided. Use `python CATNIP.py` to open the GUI,
<p align="center">
  <img src="https://github.com/snir-nimh/CATNIP/blob/master/img/gui.png" height="500"/>  
</p>
A "Quick QA" option will do an affine-only registration to quickly check the
initial quality of the registration. It downsamples the image, removes the
background, and registers to the chosen atlas using affine only registration. 
This takes about 10-15 minutes with 12 CPUs, so can be used to estimate good 
background removal parameters too.

<!-- Windows WSL -->
## Windows GUI
CATNIP and CATNIP GUI can be run under Windows WSL. 
1. Install Windows Subsystem for Linux and install Ubuntu (tested on 22.04)
   ```https://learn.microsoft.com/en-us/windows/wsl/install```
      
2. Open a WSL shell (navigate to a folder in Windows Explorer, shift+right click on
   the blank space, choose Linux shell), and install the following libraries,
   ```
   sudo apt-get update
   sudo apt install -y python3-tk libxt6 gedit pigz git net-tools
   ```
   Then close the current shell and open a new one.
3. cd to appropriate directory (all Windows drives are under /mnt, e.g. /mnt/c/ is C drive),
   download and install CATNIP
   ```
   git clone https://github.com/SNIR-NIMH/CATNIP
   ```
   Then follow the installation instructions listed above in <a href="#prerequisites">Prerequisites</a> section,
   * download and install Matlab Compiler Runtime (MCR) R2022a (v912),
   * download ANTs (tested on 2.2.0),
   * change the MCRROOT variable to the installed v912 folder in all the shell scripts,
   * add ANTs bin folder to PATH variable and add it to .bashrc.
   
5. Download and install VcXsrv
   ```
   https://github.com/marchaesen/vcxsrv/releases
   ```
6. There should be a "XLaunch" icon on Desktop after installation. If not, it should be
   located in "C:\Program Files\VcXsrv\xlaunch", or wherever VcXsrv is installed.
   
7. To open a GUI from the WSL shell, double click Xlaunch, choose "Multiple Windows",
   next, choose "Start no client", next, check "Disable access control", next, finish.
   A window will popup briefly and go away. An "X" icon will show up in the bottom right corner, leave it open.
   
8. Next, note the IP of the computer, example 192.168.1.100. The IP can also be found using ifconfig.
  Then run 
  ```
export DISPLAY=192.168.1.100:0.0
```
assuming the IP is 192.168.1.100. Setting the environment variable DISPLAY allows a GUI to open in the current shell.

8. Open the .bashrc file using gedit (```gedit ~/.bashrc```) and add the above line to set the DISPLAY 
automatically whenever a new shell is launched.

9. While VcXsrv is running, open a new shell, and test GUI feature by opening CATNIP GUI,
    ```python CATNIP.py```

### Notes
1. Number of CPUs in CATNIP can not exceed the number of cores (not number of Logical processes) shown in Task Manager.
2. In WSL, one drawback is that the network drives are not present by default, so the input and output must be on any of the local drives.
   All Windows drives are automatically mounted in WSL inside /mnt/. So D: drive is mounted in /mnt/d, etc. It is possible to mount network
   drives within WSL.
   * Mount the network drive in Windows as usual, e.g. Z:
   * Open a WSL shell, and run
   ```
   sudo mkdir /mnt/z
   sudo mount -t drvfs Z: /mnt/z
   ```

   
   


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Snehashis Roy - email@snehashis.roy@nih.gov

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- Publications -->
## Publications
<a id="1">[1]</a> 
D. Bakalar, O. Gavrilova, S. Z. Jiang, H.‐Y. Zhang, S. Roy, S. K. Williams, N. Liu, S. Wisser, T. B. Usdin, L. E. Eiden (2023). 
"Constitutive and conditional PACAP deletion reveals distinct phenotypes driven by developmental versus neurotransmitter actions of PACAP".
Journal of Neuroendocrinology,  35(11):e13286. ([Link](https://pmc.ncbi.nlm.nih.gov/articles/PMC10620107/))

* Complete Data Download [Link](https://dandiarchive.org/dandiset/001362?pos=1)

<a id="1">[2]</a> 
R. O. Goral, S. Roy, C. A. Co, R. N. Wine, P. W. Lamb, P. M. Turner, S. J. McBride, T. B. Usdin, J. L. Yakel (2025). 
"Mesoscopic analysis of GABAergic marker expression in acetylcholine neurons in the whole mouse brain".
iScience (in Press). ([Link](https://pmc.ncbi.nlm.nih.gov/articles/PMC12466781/)) 

* Complete Data Download [Link](https://doi.brainimagelibrary.org/doi/10.35077/g.1188)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- REFERENCE -->
## References
<a id="1">[1]</a> 
C. Kirst, S. Skriabine, A. Vieites-Prado, T. Topilko, P. Bertin, G. Gerschenfeld, F. Verny,
P. Topilko, N. Michalski, M. Tessier-Lavigne, and N. Renier (2020). 
Mapping the fine-scale organization and plasticity of the brain vasculature. 
Cell, 180(4):780-795.

<a id="2">[2]</a> 
N. Renier et. al. (2016)
Mapping of brain activity by automated volume analysis of immediate early genes. 
Cell, 165(7):1789-1802.

<a id="3">[3]</a> 
N. J. Tustison, B. B. Avants, P. A. Cook, Y. Zheng, A. Egan, P. A. Yushkevich, and J. C. Gee (2010)
N4ITK: Improved N3 Bias Correction. 
IEEE Trans. Med. Imaging, 29(6):1310-1320.

<a id="4">[4]</a> 
Q. Wang and S.-L. Ding et. al. (2020)
The Allen Mouse Brain Common Coordinate Framework: A 3D Reference Atlas. 
Cell, 181(4):936-953.

<a id="5">[5]</a> 
B. B. Avants, C. L. Epstein, M. Grossman, and J. C. Gee (2008)
Symmetric diffeomorphic image registration with cross-correlation: evaluating automated labeling of elderly and neurodegenerative brain. 
Medical Image Analysis, 12(1):26-41.

<a id="6">[6]</a> 
G. Loy and A. Zelinsky (2003)
Fast radial symmetry for detecting points of interest.
IEEE Trans. on Pattern Analysis and Machine Intelligence, 25(8):959-973.


<p align="right">(<a href="#readme-top">back to top</a>)</p>


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
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
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
  <img src="https://github.com/snehashis-roy/CATNIP/blob/master/img/movie1.gif" alt="animated" />
</p>

<!-- GETTING STARTED -->
## Getting Started

CATNIP is currently configured to run on a 64-bit Linux workstation or cluster. It can also
be run on any Windows workstation via a virtualization software. We have tested CATNIP on Red Hat 
Enterprise Linux 7.9, CentOS 8, and Rocky Linux 9.

CATNIP is primarily written in MATLAB, while parts (e.g., registration) of the pipeline are
run via ANTs [[5]](#5) toolbox. Note that it is not required to have an active MATLAB license as all
codes are compiled. The pipeline is optimized to use minimum amount of memory at the cost of
repeated read/write operations from disk. Minimum requirement to run the pipeline is a 8-core
CPU, 32GB RAM, and a reasonably fast drive. A recommended requirement is 12-core CPU,
64GB RAM, and a fast SSD. With Terabyte scale images, 128GB RAM and an SSD with at least
twice the size of the image are recommended to store temporary files. Administrator access is not
required and not recommended for any of the installation process.

Detailed installation instructions are given in the [documentation](CATNIP_Documentation.pdf).

### Prerequisites

* Matlab Compiler Runtime (MCR) 

Download the 64-bit Linux MCR installer for MATLAB 2019b (v97)
```
https://www.mathworks.com/products/compiler/matlab-runtime.html
```

* ANTs

Eiter download the binaries for the corresponding OS, or build from source
```
https://github.com/ANTsX/ANTs/releases
```
We have extensively tested the pipeline with ANTs version 2.2.0.


### Installation

1. Install the MCR (v97) to somewhere suitable.

2. Add the MCR installation path, i.e. the v97 directory, to all of the included shell scripts' MCRROOT variable. 
In each of the 15 shell scripts, replace the line containing ```MCRROOT=/usr/local/matlab-compiler/v97```
to the path where the MCR is installed, e.g.,
```
MCRROOT=/home/user/MCR/v97
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
2. the input image must be of one single hemisphere plus a few slices of the other hemisphere (*not* the whole brain)
3. the depth (z-axis) must be toward the midline

Please see the [documentation](CATNIP_Documentation.pdf) section 4 for details about the input image or an [example image](example_data.txt).

The main script is ```CATNIP.sh```. An example usage is,
```
./CATNIP.sh --c640 /home/user/example_data/ --o /home/user/output/ --ob no --lrflip yes --udflip yes \
--thr 1000:1000:5000 --dsfactor 6x6x5 --cellradii 2,3,4 --ncpu 16 --atlasversion v2
```

If the images have some artifacts coming from shadows, bubbles, or tearing, it is possible to add an
exclusion mask. The mask is solely used to exclude cell counts from the labels that overlap with the mask.
An example command in that scenario is the following,
```
./CATNIP.sh --c640 /home/user/example_data/ --o /home/user/output/ --ob no --lrflip yes --udflip yes \
--thr 1000:1000:5000 --dsfactor 6x6x5 --cellradii 2,3,4 --ncpu 16 --atlasversion v2 \
--exclude_mask example_data_artifact_mask.tif --mask_ovl_ratio 0.33
```

For details of each of the arguments, please refer to the [documentation](CATNIP_documentation.pdf) section 5.
These parameters are primarily applicable to 3.7x3.7x5um images. For images with different pixel sizes, the parameters
may need to be changed. 

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Snehashis Roy - email@snehashis.roy@nih.gov

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

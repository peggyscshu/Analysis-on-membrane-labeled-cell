# Analysis-on-membrane-labeled-cell
Distinguish cells labeled with membrane structure and analyze the volume and intensity in each cell in a batch mode.

#Examples
1. Membrane-tagged fluorescent cells
2. Cell wall labeled plant cells
3. Membrane channel protein-labeled cells

#Description 
1. Two scripts are available in this repository.
2.  “LifToCutline.ijm” is used to make a cutline along with the membrane signal to identify each single cell from the raw data acquired from Leica TCS-SP8 confocal microscope. The processed images will keep the resolution as the raw image and be saved as tif format in the user defined folder.
3.  These image can be further analyzed through any 3D software or through another script “Measure vol_bounding box.ijm” offered here to get the cell volume, DNA content and bounding box size. To speed up the measurement, the processed stack was binned and submitted to the 3D analysis package on Fiji.

#Instructions
LifToCutline.ijm
1.	Clone this repository to your own account.
2.	Install “Fiji is just Image J“ in your PC.
3.	Collect the input data in a folder.
4.	Launch Fiji.
5.	Execute the script under Plugins\Macros\Run 
6.	Define the input folder.
7.	Define the output folder to save the processed images.
Measure vol_bounding box.ijm
1.	Execute the script under Plugins\Macros\Run
2.	Define the input folder
3.	Define the output folder to save the image with cell indexed image and the measured data.

#References
1.	Tschumperle, D., and Deriche, R. (2005) Vector-valued image regularization with PDEs: A common framework for different applications. Ieee T Pattern Anal 27, 506-517
2.	Jaqaman, K., Loerke, D., Mettlen, M., Kuwata, H., Grinstein, S., Schmid, S. L., and Danuser, G. (2008) Robust single-particle tracking in live-cell time-lapse sequences. Nat Methods 5, 695-702
3.	Legland, D., Arganda-Carreras, I., and Andrey, P. (2016) MorphoLibJ: integrated library and plugins for mathematical morphology with ImageJ. Bioinformatics 32, 3532-3534
4.	Bolte, S., and Cordelieres, F. P. (2006) A guided tour into subcellular colocalization analysis in light microscopy. J Microsc-Oxford 224, 213-232

#Feedback
1. Made changes to the layout templates or some other part of the code? Fork this repository, make your changes, and send a pull request.
2. Do these codes help on your research? Please cite as the follows.
Skin cells undergo XXXXXXX. KY Chan, CCS Yan, HY Roan, SC Hsu, CD Hsiao, CP Hsu, CH Chen.


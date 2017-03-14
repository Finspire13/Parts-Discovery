=================================================================================================================================
Physical parts discovery dataset

Luca Del Pero, Susanna Ricco, Rahul Sukthankar, Vittorio Ferrari
=================================================================================================================================

This dataset contains 16 video shots for two different object classes: tigers and horses. 
The 16 tiger videos are divided into two sets: tigerLeft containing 8 videos showing tigers mostly facing right, and tigerRight 8 videos of tigers facing right. The same setup is used for horses (horseLeft and horseRight). If you use this dataset, please cite our CVPR 2016 paper [1].

1) VIDEO FRAMES
Each video directory (e.g. tigerLeft/1) contains individual video frames after decompression, in order to eliminate possible confusion when decoding the videos and in the frame numbering. The frames are stored in .jpg format. For each class, all frames from all shots are concatenated and named sequentially using 4 digits (e.g 0001.jpg, 0002.jpg etc).

2) SUPERPIXELS
We also provide the super pixels extracted using [2] for each video (file superPixels.mat). The file contains a cell array of length N where N is the number of frames in the video. Each cell maps each pixel to the corresponding super pixel. In each frame, the super pixel index starts at 1.

3) GROUND-TRUTH PARTS ANNOTATIONS
The ground-truth part annotations are stored in a cell array of length N (file gtLabels.mat). For each frame F with available annotations, the array contains an Nx1 array mapping each super pixel in F to the ground-truth label. For example if the Nth entry equals 3, it means that the super pixel with index N in frame F (see superPixels.mat) has part label 3. Note that we provide ground-truth annotations only for a subset of the frames in a video. We used 11 labels, with the same meaning for both horses and tigers: 1=background, 2=head, 3=torso, 4=front-left-upper-leg, 5=front-left-lower-leg, 6=front-right-upper-leg, 7=front-right-lower-leg, 8=back-left-upper-leg, 9=back-left-lower-leg, 10=back-right-upper-leg, 11=back-right-lower-leg

4) FOREGROUND SEGMENTATIONS
We provide binary segmentations computed using [3] in file segments.mat. The file contains a cell array of length N. Each cell contains a binary mask (1=foreground, 0=background).

5) TEMPORAL SUPERPIXELS
Super pixels are grouped temporally using [2] (file temporalSuperPixels.mat). This contains a cell array of length N as in superPixels.mat. However, the indexes here are common across the frames (e.g. pixels with index 57 at frame t and pixels with index 57 at frame t+1 are part of the same temporal-super pixel).


==================
References

[1] Articulated Motion Discovery using Pairs of Trajectories
Luca Del Pero, Susanna Ricco, Rahul Sukthankar, Vittorio Ferrari,
In Computer Vision and Pattern Recognition (CVPR), 2016.

[2] A video representation using temporal superpixels. 
J. Chang, D. Wei, and J. W. Fisher III.
In Computer Vision and Pattern Recognition (CVPR), 2013.

[3] Fast object segmentation in unconstrained video
Anestis Papazoglou, Vittorio Ferrari,
In International Conference on Computer Vision (ICCV), 2013


==================
Support

For any query/suggestion/complaint please send us an email:

prusso83@gmail.com (please contact this address first)
vittoferrari@gmail.com


===================
Versions history

1.0
---
- first release

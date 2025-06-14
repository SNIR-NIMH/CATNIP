import os
from glob import  glob
import sys
import argparse
import tkinter as tk
from tkinter import ttk
from tkinter import filedialog, LabelFrame, Toplevel
import warnings
warnings.filterwarnings("ignore")
from copy import deepcopy

ROOT=os.path.realpath(os.path.dirname(__file__))


# ======================================================================
root = tk.Tk()
root.title('CATNIP')
# setting the windows size
root.geometry("900x600")  # Width x height
root.resizable(False,False)

def getInputFolderPath():
    folder_selected = filedialog.askdirectory()
    inputpath.set(folder_selected)

def getOutputFolderPath():
    folder_selected = filedialog.askdirectory()
    outputpath.set(folder_selected)



def submit():
    imgdir = inputpath.get()
    outdir = outputpath.get()

    obflag = is_ob.get()
    lrflag = is_lrflipped.get()
    udflag = is_udflipped.get()
    r = cellradius.get()
    thr = threshold.get()
    n = numcpu.get()
    d1 = dsfactor1.get()
    d2 = dsfactor2.get()
    d3 = dsfactor3.get()

    c1 = cellsizepx1.get()
    c2 = cellsizepx2.get()
    bg1 = bgnoiseparam1.get()
    bg2 = bgnoiseparam2.get()

    a_ver = atlasversion.get()

    slowopt = slow.get()
    qa = quickqa.get()




    path1 = os.path.join(ROOT, 'CATNIP.sh ')
    path2 = os.path.join(ROOT, 'quick_QA_dowsample_and_register.sh ')

    if qa ==0:
        if slowopt == slowoptions[0]:
            cmd = path1 + ' --cfos ' + imgdir + ' --o ' + outdir + ' --ob ' + obflag + ' --udflip ' + udflag \
            + ' --lrflip ' +lrflag + ' --dsfactor ' + str(d1) + 'x' + str(d2) + 'x' + str(d3) + ' --thr ' + thr + \
            ' --cellradii ' + r + ' --ncpu ' + str(n) + ' --bg_noise_param ' + str(bg1) + ',' + str(bg2) + \
            ' --atlasversion ' + a_ver + ' --cellsizepx ' + str(c1) + ',' + str(c2)
        else:
            cmd = path1 + ' --cfos ' + imgdir + ' --o ' + outdir + ' --ob ' + obflag + ' --udflip ' + udflag \
                  + ' --lrflip ' + lrflag + ' --dsfactor ' + str(d1) + 'x' + str(d2) + 'x' + str(d3) + ' --thr ' + thr + \
                  ' --cellradii ' + r + ' --ncpu ' + str(n) + ' --bg_noise_param ' + str(bg1) + ',' + str(bg2) + \
                  ' --atlasversion ' + a_ver + ' --cellsizepx ' + str(c1) + ',' + str(c2) + ' --slow'


    else:
        cmd = path2 + ' ' + imgdir + ' ' + outdir + ' ' + str(d1) + 'x' + str(d2) + 'x' + str(d3) + '  ' + obflag + \
              ' ' + str(bg1) + ',' + str(bg2) + ' ' + a_ver + ' ' + str(n) + ' ' + udflag + ' ' + lrflag

    print(cmd)
    os.system(cmd)
    root.destroy()


def pop_up(msg):
    popup = Toplevel()
    #popup.attributes('-topmost', 'true')
    popup.wm_transient(root)
    label = ttk.Label(popup, text = msg , relief=tk.RAISED,anchor=tk.W)
    label.config(font=("Consolas", 14))
    label.grid()
    btn = tk.Button(popup, text ="Close", command= popup.destroy)
    btn.grid(row =1)



if __name__ == "__main__":


    # declaring string variable
    # for storing name and password
    #atlasdir_var = tk.StringVar()
    inputpath = tk.StringVar()
    outputpath = tk.StringVar()
    is_ob = tk.StringVar(root)
    is_lrflipped = tk.StringVar()
    is_udflipped = tk.StringVar()
    atlasversion = tk.StringVar()
    quickqa = tk.IntVar()

    cellradius = tk.StringVar()
    threshold = tk.StringVar()
    cellsizepx1= tk.IntVar()
    cellsizepx2 = tk.IntVar()

    bgnoiseparam1 = tk.DoubleVar()
    bgnoiseparam2 = tk.DoubleVar()


    dsfactor1 = tk.IntVar()
    dsfactor2 = tk.IntVar()
    dsfactor3 = tk.IntVar()
    numcpu = tk.IntVar()
    chunk_w = tk.IntVar()

    slow = tk.StringVar()

    yesnooptions = ["yes", "no"]
    is_ob.set(yesnooptions[1])  # Set the first option as default
    is_lrflipped.set(yesnooptions[1])
    is_udflipped.set(yesnooptions[1])

    atlasoptions = ["v1", "v2", "v3", "v4", "v5", "v6", "v7"]
    atlasversion.set(atlasoptions[4])

    slowoptions = ["Fast but not reproducible (multi-CPU)", "Slow but reproducible (single-CPU)"]
    slow.set(slowoptions[0])


    # One frame for the folder inputs
    frame1 = LabelFrame(root)
    a = tk.Label(frame1, text="Input cFOS folder containing 2D tifs", padx=10)
    a.grid(row=1, column=1, pady=5)
    E = tk.Entry(frame1, textvariable=inputpath, width=40)
    E.grid(row=1, column=2, ipadx=60, pady=5)
    btnFind = ttk.Button(frame1, text="Browse Folder", command=getInputFolderPath)
    btnFind.grid(row=1, column=3, pady=5)
    msg1 = 'Input folder must contain 2D tifs of a single channel, 3D tifs are not allowed \n'
    btn = ttk.Button(frame1, text="?", command=lambda: pop_up(msg1))
    btn.grid(row=1,column=4, ipadx=2, pady=2)

    a = tk.Label(frame1, text="Output folder where all results will be written", padx=10)
    a.grid(row=2, column=1, pady=5)
    E = tk.Entry(frame1, textvariable=outputpath, width=40)
    E.grid(row=2, column=2, ipadx=60, pady=5)
    btnFind = ttk.Button(frame1, text="Browse Folder", command=getOutputFolderPath)
    btnFind.grid(row=2, column=3, pady=5)
    frame1.grid(row=0, column=0, sticky='ew')


    # Second frame for the numeric inputs
    frame2 = LabelFrame(root)
    ob_label = tk.Label(frame2, text='Does the image have OB?', padx=40)
    obmenu = tk.OptionMenu(frame2, is_ob, *yesnooptions)
    ob_label.grid(row=0, column=0, pady=5)
    obmenu.grid(row=0, column=2, pady=5)
    # Why different variables? Python does not overwrite variables? Or does the function popup take only the last one?
    msg2 = 'If the image has complete or most of the olfactory bulb, use Yes. \n' \
          'However, it is possible that when only parts of the OB is \n' \
          'present, the registration may work better without OB. In that \n' \
          'case, it is recommended to run the pipeline with and without OB \n' \
          'and choose the one that has better registration.\n'
    btn = ttk.Button(frame2, text="?", command=lambda: pop_up(msg2))
    btn.grid(row=0, column=5, ipadx=2, pady=2)

    lrflip_label = tk.Label(frame2, text='Is the image left-right flipped w.r.t. atlas?', padx=40)
    lrflip_menu = tk.OptionMenu(frame2, is_lrflipped, *yesnooptions)
    lrflip_label.grid(row=1, column=0, pady=5)
    lrflip_menu.grid(row=1, column=2, pady=5)

    msg3 = 'Does the image need to be flipped left/right w.r.t. the atlas orientation? \n' \
          'Please check the required version of the atlas to identify the left/right flip. \n' \
           'The atlases can be found in the atlas_vXX folders in \n ' + \
           ROOT
    btn = ttk.Button(frame2, text="?", command=lambda: pop_up(msg3))
    btn.grid(row=1, column=5, ipadx=2, pady=2)

    udflip_label = tk.Label(frame2, text='Is the image up-down flipped w.r.t. atlas?', padx=40)
    udflip_menu = tk.OptionMenu(frame2, is_udflipped, *yesnooptions)
    udflip_label.grid(row=2, column=0, pady=5)
    udflip_menu.grid(row=2, column=2, pady=5)

    msg4 = 'Does the image need to be flipped up/down w.r.t. the atlas orientation? \n' \
          'Please check the required version of the atlas to identify the up/down flip. \n ' \
          'The atlases can be found in the atlas_vXX folders in \n ' + \
            ROOT
    btn = ttk.Button(frame2, text="?", command=lambda: pop_up(msg4))
    btn.grid(row=2, column=5, ipadx=2, pady=2)

    atlasversion_label = tk.Label(frame2, text='Atlas version',padx=20)
    atlasversion_menu = tk.OptionMenu(frame2, atlasversion, *atlasoptions)
    atlasversion_label.grid(row=3, column=0, pady=5)
    atlasversion_menu.grid(row=3, column=2, pady=5)

    msg5 = 'Please check the required version of the atlas needed according to the image: \n' \
            'v1: uClear atlas, sagittal, single hemisphere \n' \
            'v2: Clearmap2 atlas, sagittal, single  hemisphere. \n' \
            'v3: v2 atlas but without cerebellum \n' \
            'v4: whole  brain whole brain Clearmap2 atlas, axial, cerebellum front & brainstem back in depth \n' \
            'v5: (Default) whole brain Clearmap2 atlas, axial, cerebellum front & \n' \
                 ' brainstem back in depth, with new colormap where left and  right hemisphere \n' \
                 'labels have alternating numbers\n' \
            'v6: v5 atlas but excludes brainstem and cerebellum \n' \
            'v7: v5 atlas but in coronal orientation, OB front and cerebellum back in depth.\n'


    btn = ttk.Button(frame2, text="?", command=lambda: pop_up(msg5))
    btn.grid(row=3, column=5, ipadx=2, pady=2)


    dsfactor_label = tk.Label(frame2, text='Downsampling factor (HxWxD)',padx=20)
    ds1_entry = tk.Entry(frame2, textvariable=dsfactor1, width=4)
    ds2_entry = tk.Entry(frame2, textvariable=dsfactor2, width=4)
    ds3_entry = tk.Entry(frame2, textvariable=dsfactor3, width=4)
    dsfactor1.set(6)
    dsfactor2.set(6)
    dsfactor3.set(5)
    dsfactor_label.grid(row=4, column=0, padx=60, pady=5)
    ds1_entry.grid(row=4, column=1, padx=3, pady=5)
    ds2_entry.grid(row=4, column=2, padx=3, pady=5)
    ds3_entry.grid(row=4, column=3, padx=3, pady=5)
    msg6= 'A downsampling factor in HxWxD orientation is required for registration. \n' \
          'Default is 6x6x5. Use bigger downsampling factor (e.g. 9x9x7) for larger \n' \
          'size images. This is a crucial parameter for good registration. Choose a \n' \
          'downsampling factor so that the downsampled image size is similar to \n' \
          '528x320x277 (HxWxD) pixels and/or resolution is approximately 25x25x25um, \n' \
          'i.e. the size and resolution of the ABA atlas. After resampling, the atlas \n' \
          'should approximately be isotropic in resolution. The factor should be modified \n' \
          'based on actual brain size. For inflated brain, use bigger downsampling factor and \n' \
          'for shrunken brains, use smaller than optimal factor.\n'
    btn = ttk.Button(frame2, text="?", command=lambda: pop_up(msg6))
    btn.grid(row=4, column=5, ipadx=2, pady=2)



    msg7 = 'The numbers indicate the minimum and maximum sizes of a potential cell. \n' \
           'After thresholding, if an object is bigger than the higher limit, a \n' \
           'Watershed algorithm is run to split it. Anything smaller or bigger \n' \
           'is not counted. \n'

    cellsize_label = tk.Label(frame2, text='Cell size range in pixels: Min, Max',padx=20)
    cellsize_entry1 = tk.Entry(frame2, textvariable=cellsizepx1, width=5)
    cellsize_entry2 = tk.Entry(frame2, textvariable=cellsizepx2, width=5)
    cellsizepx1.set(9)
    cellsizepx2.set(900)
    cellsize_label.grid(row=5, column=0, pady=5)
    cellsize_entry1.grid(row=5, column=1, pady=5)
    cellsize_entry2.grid(row=5, column=2, pady=5)
    btn = ttk.Button(frame2, text="?", command=lambda: pop_up(msg7))
    btn.grid(row=5, column=5, ipadx=2, pady=2)


    msg8 = 'Number of parallel processing cores to be used. This must be less/equal \n' \
           'to the total available number of cores. Usually 8 or 12 is fine. Maximum \n' \
           'required memory is generally proportional to the number of processes. \n'
    numcpu_label = tk.Label(frame2, text='Number of CPUs to use',padx=20)
    numcpu_entry  = tk.Entry(frame2, textvariable=numcpu, width=5)
    numcpu.set(12)
    numcpu_label.grid(row=6, column=0, pady=5)
    numcpu_entry.grid(row=6, column=1, pady=5)
    btn = ttk.Button(frame2, text="?", command=lambda: pop_up(msg8))
    btn.grid(row=6, column=5, ipadx=2, pady=2)

    msg9 = 'Background noise removal parameter is used to generate a brain mask necessary \n' \
           'for registration. The first number (e.g. 50) denotes a percentile that is \n' \
           'initialized as noise background noise threshold. Use higher number (e.g. 60) \n' \
           'fpr images with heavy noise. The second number indicates a slope (>1) with \n' \
           'which the noise threshold is successively increased. 1.05 indicates the thresholds \n' \
           'are successively increased by 5% until convergence is reached. Default is 50,1.05. If \n' \
           'the brain mask too conservative, use lower number (e.g., 40,1.05). If there is a lot \n' \
           'of background left, use higher number (e.g., 60,1.07) \n'

    bgnoise_label = tk.Label(frame2, text='Background noise removal: Starting percentile, Increase factor',padx=20)
    bgnoise_entry1 = tk.Entry(frame2, textvariable=bgnoiseparam1, width=5)
    bgnoise_entry2 = tk.Entry(frame2, textvariable=bgnoiseparam2, width=5)
    bgnoiseparam1.set(50)
    bgnoiseparam2.set(1.05)
    bgnoise_label.grid(row=7, column=0, pady=5)
    bgnoise_entry1.grid(row=7, column=1, pady=5)
    bgnoise_entry2.grid(row=7, column=2, pady=5)
    btn = ttk.Button(frame2, text="?", command=lambda: pop_up(msg9))
    btn.grid(row=7, column=5, ipadx=2, pady=2)


    msg10 = 'A comma separated range of cell radii in *pixels* is needed. \n' \
            'For 3.77x3.77x5um images, the default is 2,3,4. Please estimate \n' \
            'the range of cell radii from the image and enter as a comma \n' \
            'separated string. \n'

    cellradius_label = tk.Label(frame2, text='Cell radii in pixels (MATLAB Format, comma separated)', padx=20)
    cellradius_entry = tk.Entry(frame2, textvariable=cellradius, width=20)
    cellradius.set('2,3,4')
    cellradius_label.grid(row=8, column=0, pady=5)
    cellradius_entry.grid(row=8, column=4, pady=5)
    btn = ttk.Button(frame2, text="?", command=lambda: pop_up(msg10))
    btn.grid(row=8, column=5, ipadx=0, pady=0)

    msg11 = 'Enter FRST segmentation thresholds as MATLAB start:increment:stop format. \n' \
            'FRST output is a continuous valued image. For debugging purpose, it is \n' \
            'recommeneded that a range of thresholds are used, so that segmentations \n' \
            'for each of the thresholds are generated. Example, 10000:1000:15000 means \n' \
            '6 segmentation images will be generated at thresholds 10000,11000,..,15000. \n' \
            'If not mentioned, default is 45000:5000:60000. Check the FRST images to \n' \
            'identify a suitable range of thresholds.\n'

    threshold_label = tk.Label(frame2, text='Thresholds (MATLAB Format, start:increment:stop)', padx=20)
    threshold_entry = tk.Entry(frame2, textvariable=threshold, width=20)
    threshold.set('45000:5000:60000')
    threshold_label.grid(row=9, column=0, pady=5)
    threshold_entry.grid(row=9, column=4, pady=5)
    btn = ttk.Button(frame2, text="?", command=lambda: pop_up(msg11))
    btn.grid(row=9, column=5)


    frame2.grid(row=2, column=0, sticky='ew')



    frame3 = LabelFrame(root)
    slow_label = tk.Label(frame3, text='Slow or Fast?', padx=150)
    slow_menu = tk.OptionMenu(frame3, slow, *slowoptions)
    slow_label.grid(row=0, column=0, pady=5)
    slow_menu.grid(row=0, column=1, pady=5)
    msg12 = 'Using a Slow option will make the ANTs registration use a fixed \n' \
            'seed and a single processor, as opposed to the default option of using  \n' \
            'given number of parallel processes. This also makes the registration \n' \
            'deterministic and reproducible at the cost of speed. Usually  \n' \
            'the registration takes 2-4 hours with 12 cpus. It will take   \n' \
            'approx 12 times that when this argument is added. This argument  \n' \
            'only affects the ANTs registration, the rest of the pipeline  \n' \
            'uses provided number of parallel processes.\n'
    btn = ttk.Button(frame3, text="?", command=lambda: pop_up(msg12))
    btn.grid(row=0, column=4)

    quickqa_label = tk.Label(frame3, text='Quick QA (Affine registration only, no segmentation)', padx=20)
    quickqa_button = tk.Checkbutton(frame3, text="Yes", variable=quickqa,  onvalue=1, offvalue=0)
    quickqa.set(1)
    msg13 = 'A quick Affine registration is done to assess the final registration quality. \n' \
            'The image is flipped based on left/right or up/down flip options, if needed, \n' \
            'then downsampled and background removed (using given options), and registered \n' \
            'to the given atlas version using an Affine registration with given number of CPUs. \n' \
            'This option can be used to quickly assess the appropriate atlas choice and \n' \
            'background removal parameters. The whole process takes 10-15 minutes with 12 CPUs.'
    quickqa_label.grid(row=1, column=0, pady=5)
    quickqa_button.grid(row=1, column=1, pady=5)
    btn = ttk.Button(frame3, text="?", command=lambda: pop_up(msg13))
    btn.grid(row=1, column=4)

    frame3.grid(row=3, column=0, sticky='ew')


    frame4 = LabelFrame(root, labelanchor='n')
    sub_btn = tk.Button(frame4, text='Run', command=submit)
    sub_btn.grid(row=0, column=0)
    frame4.grid(row=4, column=0, padx=20)

    # performing an infinite loop
    # for the window to display
    root.mainloop()

import os
from glob import  glob
import sys
import argparse
import tkinter as tk
from tkinter import ttk
from tkinter import filedialog, LabelFrame
import warnings
warnings.filterwarnings("ignore")

ROOT=os.path.realpath(os.path.dirname(__file__))


# ======================================================================
root = tk.Tk()
root.title('CATNIP')
# setting the windows size
root.geometry("780x540")  # Width x height
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

    lrflip_label = tk.Label(frame2, text='Is the image left-right flipped w.r.t. atlas?', padx=40)
    lrflip_menu = tk.OptionMenu(frame2, is_lrflipped, *yesnooptions)
    lrflip_label.grid(row=1, column=0, pady=5)
    lrflip_menu.grid(row=1, column=2, pady=5)

    udflip_label = tk.Label(frame2, text='Is the image up-down flipped w.r.t. atlas?', padx=40)
    udflip_menu = tk.OptionMenu(frame2, is_udflipped, *yesnooptions)
    udflip_label.grid(row=2, column=0, pady=5)
    udflip_menu.grid(row=2, column=2, pady=5)

    atlasversion_label = tk.Label(frame2, text='Atlas version',padx=20)
    atlasversion_menu = tk.OptionMenu(frame2, atlasversion, *atlasoptions)
    atlasversion_label.grid(row=3, column=0, pady=5)
    atlasversion_menu.grid(row=3, column=2, pady=5)


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


    cellsize_label = tk.Label(frame2, text='Cell size range in pixels: Min, Max',padx=20)
    cellsize_entry1 = tk.Entry(frame2, textvariable=cellsizepx1, width=5)
    cellsize_entry2 = tk.Entry(frame2, textvariable=cellsizepx2, width=5)
    cellsizepx1.set(9)
    cellsizepx2.set(900)
    cellsize_label.grid(row=5, column=0, pady=5)
    cellsize_entry1.grid(row=5, column=1, pady=5)
    cellsize_entry2.grid(row=5, column=2, pady=5)

    numcpu_label = tk.Label(frame2, text='Number of CPUs to use',padx=20)
    numcpu_entry  = tk.Entry(frame2, textvariable=numcpu, width=5)
    numcpu.set(12)
    numcpu_label.grid(row=6, column=0, pady=5)
    numcpu_entry.grid(row=6, column=1, pady=5)

    bgnoise_label = tk.Label(frame2, text='Background noise removal: Starting percentile, Increase factor',padx=20)
    bgnoise_entry1 = tk.Entry(frame2, textvariable=bgnoiseparam1, width=5)
    bgnoise_entry2 = tk.Entry(frame2, textvariable=bgnoiseparam2, width=5)
    bgnoiseparam1.set(50)
    bgnoiseparam2.set(1.05)
    bgnoise_label.grid(row=7, column=0, pady=5)
    bgnoise_entry1.grid(row=7, column=1, pady=5)
    bgnoise_entry2.grid(row=7, column=2, pady=5)

    cellradius_label = tk.Label(frame2, text='Cell radii in pixels (MATLAB Format, comma separated)', padx=20)
    cellradius_entry = tk.Entry(frame2, textvariable=cellradius, width=20)
    cellradius.set('2,3,4,5')
    cellradius_label.grid(row=8, column=0, pady=5)
    cellradius_entry.grid(row=8, column=4, pady=5)

    threshold_label = tk.Label(frame2, text='Thresholds (MATLAB Format, start:increment:stop)', padx=20)
    threshold_entry = tk.Entry(frame2, textvariable=threshold, width=20)
    threshold.set('10000:10000:50000')
    threshold_label.grid(row=9, column=0, pady=5)
    threshold_entry.grid(row=9, column=4, pady=5)

    frame2.grid(row=2, column=0, sticky='ew')

    frame3 = LabelFrame(root)
    slow_label = tk.Label(frame3, text='Slow or Fast?', padx=150)
    slow_menu = tk.OptionMenu(frame3, slow, *slowoptions)
    slow_label.grid(row=0, column=0, pady=5)
    slow_menu.grid(row=0, column=1, pady=5)

    quickqa_label = tk.Label(frame3, text='Quick QA (Affine registration only, no segmentation)', padx=20)
    quickqa_button = tk.Checkbutton(frame3, text="Yes", variable=quickqa,  onvalue=1, offvalue=0)
    quickqa.set(1)
    quickqa_label.grid(row=1, column=0, pady=5)
    quickqa_button.grid(row=1, column=1, pady=5)
    frame3.grid(row=3, column=0, sticky='ew')

    frame4 = LabelFrame(root, labelanchor='n')
    sub_btn = tk.Button(frame4, text='Run', command=submit)
    sub_btn.grid(row=0, column=0)
    frame4.grid(row=4, column=0, padx=20)

    # performing an infinite loop
    # for the window to display
    root.mainloop()

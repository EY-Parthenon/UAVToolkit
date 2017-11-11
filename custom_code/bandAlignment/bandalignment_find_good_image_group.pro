; (c) 2017 Exelis Visual Information Solutions, Inc., a subsidiary of Harris Corporation.

;+
; :Description:
;    Procedure that will automatically find the best image group to
;    use for the band-band registration for a given set of data. This
;    routine is data-set independent and just relies on the `GROUPS`
;    keyword below.
;
;
;
; :Keywords:
;    GROUPS: input, required, type=hash/orderedhash
;      Set this input keyword to an ordered hash where the key/value
;      pairs correspond to  the folder and base name of the image groups and an array of
;      the fully-qualified paths to the iamges for that group. For example, here is
;      an image group for the MicaSense RedEdge:
;      
;      "C:\\Users\\Traininglead\\Desktop\\test\\north_block_east_west\\000\\IMG_0289":[ 
;        "C:\\Users\\Traininglead\\Desktop\\test\\north_block_east_west\\000\\IMG_0289_1.tif", 
;        "C:\\Users\\Traininglead\\Desktop\\test\\north_block_east_west\\000\\IMG_0289_2.tif", 
;        "C:\\Users\\Traininglead\\Desktop\\test\\north_block_east_west\\000\\IMG_0289_3.tif", 
;        "C:\\Users\\Traininglead\\Desktop\\test\\north_block_east_west\\000\\IMG_0289_4.tif", 
;        "C:\\Users\\Traininglead\\Desktop\\test\\north_block_east_west\\000\\IMG_0289_5.tif"
;      ]
;    INPUTDIR: in, optional, type=string
;      This optional keyword can be set to the directory that wants to be searched for
;      image groups. You can use this if you don't pass in the `GROUPS` keyword. This 
;      assumes that there are only MicaSense RedEdge images present.
;    OUTPUT_IMAGE_GROUP: out, requried, type=string
;      The key name for the image group that is the most likely candidate for providing
;      good band-band registration results.
;    KAPPA_FILTER: in, optional, type=boolean
;      This optional keyword will filter out scenes that may be associated with fixed-wing
;      drones turning around. You don't want to use these images for generating tiepoints
;      because they do not have the same viewing geometry as the nadir images.
;    BASEBAND: in, optional, type=int, default=0
;      This optional keyword specifies the zero-based band number that you want to use for
;      evaluating the quality of the band for reference tiepoints.
;
; :Author: Zachary Norman - znorman@harris.com
;-
pro bandalignment_find_good_image_group, $
  GROUPS = groups, $
  OUTPUT_IMAGE_GROUP = output_image_group,$
  KAPPA_FILTER = kappa_filter,$
  BASEBAND = baseband
  compile_opt idl2, hidden
  
  ;check to see if ENVI is running
  e = envi(/current)
  if (e eq !NULL) then begin
    e = envi(/headless)
  endif
  
  ;check what the baseband is
  ;default is first
  if (baseband eq !NULL) then begin
    baseband = 0
  endif 
  
  ;get the group names that fall within approximate straight lines if asked for
  if keyword_set(kappa_filter) then begin
    groupNames = bandalignment_simple_kappa_filter(groups)
  endif else begin
    groupNames = (groups.keys()).toArray()
  endelse
  
  ;preallocate an array to hold our metric for the best image to register
  edges = dblarr(n_elements(groupNames))
  
  ;iterate over each image group
  foreach groupName, groupNames, i do begin
    ;get the file names for each group
    images = groups[groupName]
    
    ;open raster and get data
    raster = e.openRaster(images[baseband])
    dat = raster.getdata()
    raster.close
    
    ;find the total number of edges in the image
    edges[i] = mean(sobel(dat))
  endforeach  
  
  ;get the min/max values
  maxEdge = max(edges, idx_max)
  minEdge = min(edges, idx_min)

  ;return the iamge with the largest mean value of edges
  output_image_group = groupNames[idx_max]
end
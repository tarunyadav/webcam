<html>
<head>
<title><?php include("title.txt") ?></title>
  <link rel="stylesheet" type="text/css" href="basic.css" media="all">
</head>
<body>
<div id="wrap">
  <div id="header">
    <?php if(file_exists("beachcam/movie_thumb.html"))
	     include("beachcam/movie_thumb.html");
	  else
	     print "Yesterday's movie not available";
	  ?>
  </div>
  <div id="main">
    <?php if(file_exists("beachcam/current.html"))
	     include("beachcam/current.html");
	  else
	     print "Current picture not available";
	  ?>
  </div>
  <div id="sidebar">
    <?php
       $index_files=glob("beachcam/????-??_index.html");
       if( is_array($index_files) && count($index_files) > 0 )  {
          foreach($index_files as $index_filename) {
            $index_files[] = $index_filename;
          } rsort($index_files);
          if ($index_files) {
            foreach ($index_files as $name)
                include($name);
          }
       }
       else
         print "No history available";
?>
  </div>
</div>

<div class="preload">
</div>


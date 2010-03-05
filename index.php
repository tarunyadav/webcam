<html>
<head>
<title>BeachCam</title>
  <link rel="stylesheet" type="text/css" href="basic.css" media="all">
</head>
<body>
<div id="wrap">
  <div id="header">
    <?php include("beachcam/movie_thumb.html"); ?>
  </div>
  <div id="main">
  <?php include("beachcam/current.html"); ?>
  </div>
  <div id="sidebar">
    <?php
    foreach(glob("beachcam/????-??_index.html") as $index_filename) {
        $files[] = $index_filename;
    } rsort($files);

    if ($files) {
        foreach ($files as $name) {
            include($name);
        }
    }
?>
  </div>
</div>

<div class="preload">
</div>


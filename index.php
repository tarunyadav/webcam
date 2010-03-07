<html>
<head>
<title><?php include("title.txt") ?></title>
  <link rel="stylesheet" type="text/css" href="basic.css" media="all">
</head>
<body>
<div id="wrap">
  <div id="header">
    <?php include("webcam/movie_thumb.html"); ?>
  </div>
  <div id="main">
  <?php include("webcam/current.html"); ?>
  </div>
  <div id="sidebar">
    <?php
    foreach(glob("webcam/????-??_index.html") as $index_filename) {
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


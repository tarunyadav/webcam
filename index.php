<html>
<head>
<title>KonaCam</title>
  <link rel="stylesheet" type="text/css" href="basic.css" media="all">
</head>
<body>
<div id="wrap">
  <div id="header">
    <?php include("konacam1/movie_thumb.html"); ?>
  </div>
  <div id="main">
  <?php include("konacam1/current.html"); ?>
  <?php include("konacam2/current.html"); ?>
  </div>
  <div id="sidebar">
    <?php
    foreach(glob("konacam1/????-??_index.html") as $index_filename) {
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


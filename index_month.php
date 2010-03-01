<html>
<head>
<title>KonaCam</title>
  <link rel="stylesheet" type="text/css" href="/basic.css" media="all">
</head>
<body>
<div id="wrap">
<div id="onecolumn">
    <?php
    foreach(glob("*.html") as $index_filename) {
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

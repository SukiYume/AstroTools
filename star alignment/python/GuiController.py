#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Author: Jiajie Zhang
Email: zhangjiajie043@gmail.com
"""

import os
import logging
import numpy as np
import cv2
from PyQt5.QtWidgets import QFileDialog
from PyQt5.QtCore import (QThread, pyqtSignal)
from DataModel import (DataModel, ImageProcessing)


class GuiController(object):
    def __init__(self, gui, data_model):
        super(GuiController, self).__init__()
        self.logger = logging.getLogger(self.__class__.__name__)
        self.gui = gui
        self.data_model = data_model
        self.load_img_thread = LoadImageThread([], self.data_model)
        self.merge_img_thread = MergeImageThread(self.data_model)

        # Left file list panel
        self.gui.list_panel.buttons["Add"].clicked.connect(self.add_images)
        self.gui.list_panel.buttons["Clear"].clicked.connect(self.clear)
        self.gui.list_panel.buttons["Merge"].clicked.connect(self.merge_images)
        self.gui.list_panel.buttons["Save"].clicked.connect(self.save_image)
        self.gui.list_panel.file_list.currentRowChanged.connect(self.list_row_changed)
        self.gui.list_panel.merge_option_group.button_clicked.connect(self.merge_option_changed)
        self.last_list_row = -1

        # Center image viewer panel
        self.gui.center_panel.set_ref_btn.clicked.connect(self.set_ref_ind)
        self.gui.center_panel.prev_btn.clicked.connect(self.prev_image)
        self.gui.center_panel.next_btn.clicked.connect(self.next_image)

        # Right info panel
        self.gui.info_panel.set_btn.clicked.connect(lambda: self.gui.set_focal_dialog.exec_())

        # Dialogs
        self.gui.loading_img_dialog.cancel_btn.clicked.connect(self.load_img_thread.cancel)
        self.gui.set_focal_dialog.accepted.connect(self.set_focal_length)
        self.gui.merge_info_dialog.btn_cancel.clicked.connect(self.merge_img_thread.cancel)

        # Threads
        self.load_img_thread.finished.connect(self.loading_img_finish)
        self.load_img_thread.progress.connect(self.loading_img_progress)
        self.merge_img_thread.progress.connect(self.merge_image_progress)
        self.merge_img_thread.finished.connect(self.merge_image_finish)

    def add_images(self):
        self.logger.debug("add_images()")
        file_names = QFileDialog.getOpenFileNames(self.gui, "Open files",
                                                  self.gui.config.get("IMG_PATH", "./"), "Tiff files (*.tif *.tiff)")
        if len(file_names[0]) == 0:
            return
        else:
            img_dir, _ = os.path.split(file_names[0][0])
            self.gui.config["IMG_PATH"] = img_dir

        self.load_img_thread.set_path_list(file_names[0])
        self.load_img_thread.start()
        self.gui.loading_img_dialog.clear()
        self.gui.loading_img_dialog.exec_()

    def merge_images(self):
        self.logger.debug("merge_images()")
        if not self.data_model.has_image():
            return
        self.merge_img_thread.start()
        self.gui.merge_info_dialog.clear()
        self.gui.merge_info_dialog.exec_()

    def merge_image_finish(self):
        if not self.gui.merge_info_dialog.isActiveWindow():
            return
        self.logger.debug("merge_image_finish()")
        self.gui.merge_info_dialog.done(0)
        total = self.data_model.total_images()
        self.gui.update()
        if self.data_model.has_sky_result() or self.data_model.has_ground_result():
            self.gui.list_panel.file_list.setCurrentRow(total)

    def merge_image_progress(self, info, curr, total):
        self.logger.debug("merge_image_progress()")
        self.logger.debug("info: %s, %d/%d", info, curr, total)
        self.gui.merge_info_dialog.set_status(info, curr, total)

    def merge_option_changed(self, ind):
        self.logger.debug("merge_option_changed()")
        self.data_model.merge_option_type = ind
        self.gui.list_panel.update()
        self.gui.center_panel.update()

    def loading_img_progress(self, curr, total):
        self.logger.debug("loading_img_progress()")
        self.logger.debug("curr: %d, total: %d", curr, total)
        self.gui.loading_img_dialog.set_status(curr, total)
        self.gui.list_panel.update()

    def loading_img_finish(self):
        self.logger.debug("loading_img_finish()")
        self.gui.loading_img_dialog.done(0)
        ind = self.gui.list_panel.file_list.currentRow()
        ref_ind = self.data_model.ref_ind
        if ind == ref_ind and not self.data_model.images[ref_ind].focal_len:
            self.gui.set_focal_dialog.exec_()

    def save_image(self):
        self.logger.debug("save_image()")
        if not self.data_model.has_sky_result() and not self.data_model.has_ground_result():
            return
        if self.data_model.merge_option_type == DataModel.ALIGN_STARS and not self.data_model.has_sky_result():
            return
        if self.data_model.merge_option_type == DataModel.ALIGN_GROUND and not self.data_model.has_ground_result():
            return

        path = self.data_model.image_dir
        if not path:
            path = "./"

        file_name = QFileDialog.getSaveFileName(self.gui, "Save file",
                                                path, "Tiff files (*.tif *.tiff)")
        self.logger.debug("file_name: %s", file_name)
        if len(file_name[0]) > 0:
            if self.data_model.merge_option_type == DataModel.ALIGN_STARS and self.data_model.has_sky_result():
                img = (self.data_model.final_sky_img * np.iinfo(np.uint16).max).astype("uint16")
            elif self.data_model.merge_option_type == DataModel.ALIGN_GROUND and self.data_model.has_ground_result():
                img = (self.data_model.final_ground_img * np.iinfo(np.uint16).max).astype("uint16")
            else:
                img = None
            
            if img is None:
                return
            ref_ind = self.data_model.ref_ind
            ImageProcessing.save_tif_image(file_name[0], img, self.data_model.images[ref_ind].exif_info)

    def list_row_changed(self, row):
        self.logger.debug("list_row_changed()")
        self.gui.center_panel.update_buttons()
        # if row < 0 or row == self.last_list_row:
        #     return

        self.logger.debug("current row: %d", row)
        self.gui.center_panel.update_image()
        self.gui.info_panel.update()
        self.last_list_row = row

    def set_ref_ind(self):
        self.logger.debug("set_ref_ind()")
        row = self.gui.list_panel.file_list.currentRow()
        self.data_model.ref_ind = row
        if not self.data_model.images[row].focal_len:
            self.gui.set_focal_dialog.exec_()

        self.gui.list_panel.update()
        self.gui.center_panel.update_buttons()
        self.gui.info_panel.update()

    def set_focal_length(self):
        self.logger.debug("set_focal_length()")
        row = self.gui.list_panel.file_list.currentRow()
        dialog_focal = self.gui.set_focal_dialog.effective_focal
        self.logger.debug("current row: %d, dialog focal: %f", row, dialog_focal)
        if dialog_focal and row >= 0:
            self.data_model.images[row].focal_len = dialog_focal

        self.gui.info_panel.update()

    def prev_image(self):
        self.logger.debug("prev_image()")
        row = self.gui.list_panel.file_list.currentRow()
        if row > 0:
            row -= 1
            self.gui.list_panel.file_list.setCurrentRow(row)

    def next_image(self):
        self.logger.debug("next_image()")
        row = self.gui.list_panel.file_list.currentRow()
        total = self.gui.list_panel.file_list.count()
        if row < total - 1:
            row += 1
            self.gui.list_panel.file_list.setCurrentRow(row)

    def clear(self):
        self.logger.debug("clear()")
        self.gui.clear()
        self.data_model.clear_images()
        self.load_img_thread.clear()
        self.gui.update()

        self.last_list_row = -1


class LoadImageThread(QThread):
    finished = pyqtSignal()
    progress = pyqtSignal(int, int)

    def __init__(self, path_list, data_model):
        super(LoadImageThread, self).__init__()
        self.logger = logging.getLogger(self.__class__.__name__)

        self.path_list = path_list[:]
        self.data_model = data_model
        self.alive = False

    def set_path_list(self, path_list):
        self.path_list = path_list[:]
        self.logger.debug("set path list: %s", self.path_list)

    def run(self):
        self.alive = True
        image_loaded = 0
        for p in self.path_list:
            if not self.alive:
                self.exit(2)
                break
            if os.path.isfile(p):
                added = self.data_model.add_image(p)
                if added:
                    self.data_model.reset_result()
                image_loaded += 1
                self.progress.emit(image_loaded, len(self.path_list))
        self.finished.emit()
        self.alive = False

    def cancel(self):
        self.alive = False
        self.finished.emit()

    def clear(self):
        self.path_list = []


class MergeImageThread(QThread):
    finished = pyqtSignal()
    progress = pyqtSignal("QString", int, int)

    def __init__(self, data_model):
        super(MergeImageThread, self).__init__()
        self.logger = logging.getLogger(self.__class__.__name__)

        self.data_model = data_model
        self.alive = False

        self.prg_step = 0
        self.total_prg_steps = 0

    def _detect_star_points(self, img, resize_length):
        if not self.alive:
            self.exit(2)
        self.progress.emit("Detecting start points...", self.prg_step, self.total_prg_steps)
        pts, vol = ImageProcessing.detect_star_points(img.fullsize_gray_image, resize_length=resize_length)
        return pts, vol

    def _convert_to_spherical_coord(self, pts, img_size, f):
        if not self.alive:
            self.exit(2)
        self.progress.emit("Extracting features...", self.prg_step, self.total_prg_steps)
        sph = ImageProcessing.convert_to_spherical_coord(pts, np.array(img_size), f)
        return sph

    def _extract_point_features(self, img, pts, sph, vol):
        if not self.alive:
            self.exit(2)
        feature = ImageProcessing.extract_point_features(sph, vol)
        img.features["pts"] = pts
        img.features["sph"] = sph
        img.features["vol"] = vol
        img.features["feature"] = feature

    def _find_initial_match(self, img, ref_img):
        if not self.alive:
            self.exit(2)
        self.progress.emit("Matching points...", self.prg_step, self.total_prg_steps)
        pair_idx = ImageProcessing.find_initial_match(img.features, ref_img.features)
        return pair_idx

    def _fine_tune_transform(self, img, ref_img, init_pair_idx, img_size):
        if not self.alive:
            self.exit(2)
        tf, pair_idx = ImageProcessing.fine_tune_transform(img.features, ref_img.features, init_pair_idx)
        img.tf = tf
        self.progress.emit("Find {0} matches.".format(len(pair_idx)), self.prg_step, self.total_prg_steps)
        img_tf = cv2.warpPerspective(img.original_image, tf[0], img_size)
        return ImageProcessing.convert_to_float(img_tf), len(pair_idx)

    def run(self):
        if not self.data_model.has_image():
            self.exit(1)
        if self.alive:
            return

        self.alive = True
        total_images = self.data_model.total_images()
        ref_ind = self.data_model.ref_ind
        ref_img = self.data_model.images[ref_ind]
        f = ref_img.focal_len
        img_shape = ref_img.fullsize_gray_image.shape
        merge_option_type = self.data_model.merge_option_type
        if merge_option_type == DataModel.ALIGN_STARS:
            self.data_model.reset_final_sky()
        elif merge_option_type == DataModel.ALIGN_GROUND:
            self.data_model.reset_final_ground()

        if merge_option_type == DataModel.ALIGN_STARS:
            self.total_prg_steps = total_images * 5 - 2
        elif merge_option_type == DataModel.ALIGN_GROUND:
            self.total_prg_steps = total_images

        resize_length = 2200
        while True:
            try:
                self.prg_step = 0
                if merge_option_type == DataModel.ALIGN_STARS:
                    pts, vol = self._detect_star_points(ref_img, resize_length)
                    ref_pts_num = len(pts)
                    self.prg_step += 1
                if not self.alive:
                    self.exit(2)
                    return

                if merge_option_type == DataModel.ALIGN_STARS:
                    sph = self._convert_to_spherical_coord(pts, (img_shape[1], img_shape[0]), f)
                    self._extract_point_features(ref_img, pts, sph, vol)
                    self.prg_step += 1
                if not self.alive:
                    self.exit(2)
                    return

                if merge_option_type == DataModel.ALIGN_STARS:
                    self.data_model.update_final_sky(ImageProcessing.convert_to_float(ref_img.original_image))
                elif merge_option_type == DataModel.ALIGN_GROUND:
                    self.data_model.update_final_ground(ImageProcessing.convert_to_float(ref_img.original_image))
                for i in range(total_images):
                    if i == ref_ind:
                        continue
                    img = self.data_model.images[i]
                    if merge_option_type == DataModel.ALIGN_STARS:
                        pts, vol = self._detect_star_points(img, resize_length)
                        self.prg_step += 1
                    if not self.alive:
                        self.exit(2)
                        return

                    if merge_option_type == DataModel.ALIGN_STARS:
                        sph = self._convert_to_spherical_coord(pts, (img_shape[1], img_shape[0]), f)
                        self._extract_point_features(img, pts, sph, vol)
                        self.prg_step += 1
                    if not self.alive:
                        self.exit(2)
                        return

                    if merge_option_type == DataModel.ALIGN_STARS:
                        pair_idx = self._find_initial_match(img, ref_img)
                        self.prg_step += 1
                    if not self.alive:
                        self.exit(2)
                        return

                    if merge_option_type == DataModel.ALIGN_STARS:
                        img_tf, ps = self._fine_tune_transform(img, ref_img, pair_idx, (img_shape[1], img_shape[0]))
                        self.prg_step += 1
                    if not self.alive:
                        self.exit(2)
                        return
                    self.logger.debug("ps = %s, len(pts) = %s", ps, len(pts))
                    if ps * 1.0 / len(pts) < 0.4:
                        raise ValueError, "Not enough matches!"

                    self.progress.emit("Merge image...", self.prg_step, self.total_prg_steps)
                    self.prg_step += 1
                    if merge_option_type == DataModel.ALIGN_STARS:
                        self.data_model.update_final_sky(img_tf)
                    elif merge_option_type == DataModel.ALIGN_GROUND:
                        self.data_model.update_final_ground(ImageProcessing.convert_to_float(img.original_image))
                    if not self.alive:
                        self.exit(2)
                        return
                break
            except ValueError as e:
                if resize_length + 1000 < max(img_shape):
                    resize_length += 1000
                    continue
                else:
                    raise ValueError, "Not enough matches!"

        if not self.alive:
            self.exit(2)
            return
        self.progress.emit("Generating result preview...", self.prg_step, self.total_prg_steps)
        self.prg_step += 1
        if self.data_model.has_sky_result():
            self.data_model.final_sky_qpix = ImageProcessing.convert_to_qpix(self.data_model.final_sky_img)
        if self.data_model.has_ground_result():
            self.data_model.final_ground_qpix = ImageProcessing.convert_to_qpix(self.data_model.final_ground_img)
        self.finished.emit()
        self.alive = False

    def cancel(self):
        merge_option_type = self.data_model.merge_option_type
        if merge_option_type == DataModel.ALIGN_STARS:
            self.data_model.reset_final_sky()
        elif merge_option_type == DataModel.ALIGN_GROUND:
            self.data_model.reset_final_ground()
        # self.data_model.reset_result()
        self.alive = False
        self.finished.emit()

    def exit(self, code=0):
        self.logger.debug("exit with code: %d", code)
        self.alive = False
        super(MergeImageThread, self).exit(code)

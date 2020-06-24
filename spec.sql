create or replace PACKAGE PKG_2020MAIN IS
--
-- Author: Beomsang Kim
-- Created Date: 30-MAY-2020
-- Modified Date: 
-- Purpose of Program: Foracasting 14 days average ennergy consumption of each TNI, LR and FRMP
--                     Sroaring into LOCAL_RM16
--                     Generating UTL report and XML file and stoaring in U13340106_DIR
--

--
-- All of constants will be stoared into DBP_PARAMETER table and called via function get_param
-- con_example := get_param(¡®CATEGORY NAME¡¯, ¡®CODE NAME¡¯);
--

--
-- Design Document for this program is provided
--

procedure rm16_forecast; --Entry Module

END PKG_2020MAIN;